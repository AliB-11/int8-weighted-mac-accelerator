"""
cocotb + Verilator integration tests for conv_top (the serial wrapper).

Every test drives the real top-level ports (start / w_* / x_* / y_*) the way a
host would, collects the output stream, and compares it bit-exactly against
the NumPy golden model in golden_model.py.

Timing convention (important for cocotb + Verilator): all inputs are driven and
all outputs are sampled on the FALLING clock edge, i.e. in the middle of a
cycle when every register has settled. This avoids the simulator-dependent
race you get when sampling right at the rising edge. A valid/ready transfer
happens at the next rising edge iff valid and ready were both high during the
cycle, and ready only depends on registered state, so it can be read safely at
the falling edge.

Configuration (environment variables, set by the Makefile):
    K                 kernel size, must match the -GK=... the RTL was built with
    NUM_TRIALS        random trials in test_random_trials        (default 10000)
    N_SAMPLES         stream length in test_random_trials        (default 32)
    NUM_STALL_TRIALS  random trials with valid stalls            (default 500)
    SEED              base seed for all random data              (default 1234)
"""

import os

import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

import golden_model as gm

DW = 8
MASK = (1 << DW) - 1

K = int(os.environ.get("K", "5"))
ACC_W = gm.acc_width(K, DW)
NUM_TRIALS = int(os.environ.get("NUM_TRIALS", "10000"))
N_SAMPLES = int(os.environ.get("N_SAMPLES", "32"))
NUM_STALL_TRIALS = int(os.environ.get("NUM_STALL_TRIALS", "500"))
SEED = int(os.environ.get("SEED", "1234"))


def to_signed(raw, width):
    """Interpret an unsigned integer as a `width`-bit two's-complement value."""
    raw = int(raw) & ((1 << width) - 1)
    return raw - (1 << width) if raw >> (width - 1) else raw


class ConvHarness:
    """Host-side driver + output monitor for conv_top."""

    def __init__(self, dut, seed=SEED):
        self.dut = dut
        self.outputs = []  # signed accumulator values captured while y_valid was high
        self.rng = np.random.default_rng(seed)

    # ------------------------------------------------------------------ setup
    async def setup(self):
        """Initialize inputs, start the clock and monitor, and reset the DUT."""
        d = self.dut
        d.rst_n.value = 0
        d.start.value = 0
        d.w_valid.value = 0
        d.w_data.value = 0
        d.x_valid.value = 0
        d.x_data.value = 0
        d.x_last.value = 0
        d.y_ready.value = 1
        cocotb.start_soon(Clock(d.clk, 10, unit="ns").start())
        cocotb.start_soon(self._monitor())
        await self.reset()

    async def idle(self, n):
        for _ in range(n):
            await FallingEdge(self.dut.clk)

    async def reset(self, cycles=3):
        """Assert the (asynchronous, active-low) reset for `cycles` cycles."""
        d = self.dut
        d.start.value = 0
        d.w_valid.value = 0
        d.x_valid.value = 0
        d.x_last.value = 0
        d.rst_n.value = 0
        await self.idle(cycles)
        d.rst_n.value = 1
        await self.idle(1)
        self.outputs.clear()

    async def _monitor(self):
        """Capture one output every cycle y_valid is high (there is no backpressure)."""
        while True:
            await FallingEdge(self.dut.clk)
            if int(self.dut.y_valid.value):
                self.outputs.append(to_signed(self.dut.y_data.value, ACC_W))

    # --------------------------------------------------------------- stimulus
    async def _pulse_start(self):
        await FallingEdge(self.dut.clk)
        self.dut.start.value = 1
        await FallingEdge(self.dut.clk)
        self.dut.start.value = 0

    async def _stream(self, valid, ready, data, values, *, last=None,
                      assert_last=True, stall_prob=0.0, name="stream"):
        """
        Send `values` through a valid/ready channel, one item per accepted cycle.
        `last` (optional) is asserted together with the final item.
        `stall_prob` inserts random idle cycles *between* transfers (valid is
        never dropped while an item is waiting to be accepted).
        """
        n = len(values)
        max_cycles = 100 + 50 * n
        cycles = 0
        i = 0
        holding = False
        while i < n:
            await FallingEdge(self.dut.clk)
            cycles += 1
            assert cycles <= max_cycles, f"{name}: timed out waiting for ready ({i}/{n} items sent)"

            if (not holding) and stall_prob > 0.0 and self.rng.random() < stall_prob:
                valid.value = 0
                if last is not None:
                    last.value = 0
                continue

            valid.value = 1
            data.value = int(values[i]) & MASK
            if last is not None:
                last.value = 1 if (assert_last and i == n - 1) else 0

            if int(ready.value):  # ready is registered state only: transfer happens at the next rising edge
                i += 1
                holding = False
            else:
                holding = True

        await FallingEdge(self.dut.clk)
        valid.value = 0
        data.value = 0
        if last is not None:
            last.value = 0

    async def _collect(self, count, *, extra_cycles=0):
        """Wait until `count` outputs have been captured (bounded)."""
        timeout = 200 + 20 * (count + K) + extra_cycles
        for _ in range(timeout):
            if len(self.outputs) >= count:
                return
            await FallingEdge(self.dut.clk)
        raise AssertionError(f"timed out: only {len(self.outputs)}/{count} outputs after {timeout} cycles")

    async def run(self, kernel, samples, *, w_stall=0.0, x_stall=0.0, settle=3, tag=""):
        """
        Run one full convolution (start -> load kernel -> stream samples -> collect
        outputs), assert the result matches the golden model bit-exactly, and
        return the captured outputs.

        `settle` = idle cycles spent after the expected outputs arrive, during
        which NO further output may appear (catches spurious extra outputs).
        """
        kernel = np.asarray(kernel, dtype=np.int8)
        samples = np.asarray(samples, dtype=np.int8)
        assert len(kernel) == K, f"kernel length {len(kernel)} != K={K}"
        assert len(samples) >= 1, "stream must contain at least one sample (x_last rides on the final sample)"

        expected = gm.conv1d_int8(samples, kernel)
        count = len(expected)
        self.outputs.clear()

        await self._pulse_start()
        await self._stream(self.dut.w_valid, self.dut.w_ready, self.dut.w_data, kernel,
                           stall_prob=w_stall, name="weights")
        await self._stream(self.dut.x_valid, self.dut.x_ready, self.dut.x_data, samples,
                           last=self.dut.x_last, stall_prob=x_stall, name="samples")
        await self._collect(count)

        # With zero expected outputs the FSM still needs a few cycles to return to IDLE.
        await self.idle(max(settle, 2 if count == 0 else 0))

        got = np.array(self.outputs, dtype=np.int64)
        label = f"[{tag}] " if tag else ""
        assert len(got) == count, (
            f"{label}output count mismatch: expected {count} (N={len(samples)}, K={K}), got {len(got)}")
        if count:
            bad = np.nonzero(got != expected.astype(np.int64))[0]
            assert bad.size == 0, (
                f"{label}mismatch at output index {int(bad[0])}: expected {int(expected[bad[0]])}, "
                f"got {int(got[bad[0]])}\n  kernel : {kernel.tolist()}\n  samples: {samples.tolist()}\n"
                f"  expected: {expected.tolist()}\n  got     : {got.tolist()}")
        return got


# ====================================================================== tests
@cocotb.test()
async def test_known_answer(dut):
    """Small hand-checkable examples."""
    h = ConvHarness(dut)
    await h.setup()

    if K == 3:  # hand-checked in golden_model.py: [3,5,8,2,6] * [1,0,-1] -> [-5,3,2]
        x = np.array([3, 5, 8, 2, 6], dtype=np.int8)
        w = np.array([1, 0, -1], dtype=np.int8)
        got = await h.run(w, x, tag="hand-checked K=3")
        assert got.tolist() == [-5, 3, 2]

    await h.run(gm.ramp_vector_int8(K, start=1), gm.ramp_vector_int8(2 * K + 3, start=-4), tag="ramp x ramp")
    await h.run(gm.ones_vector_int8(K), gm.ones_vector_int8(K + 4), tag="ones x ones")
    dut._log.info("known-answer tests passed")


@cocotb.test()
async def test_delta_kernels(dut):
    """
    A kernel with a single 1 at tap k must return the input shifted by k.
    This pins down the window/weight index pairing (no accidental kernel flip),
    independently of the golden model.
    """
    h = ConvHarness(dut)
    await h.setup()

    n = 3 * K + 4
    samples = gm.random_vector_int8(n, seed=SEED)
    for k in range(K):
        kernel = np.zeros(K, dtype=np.int8)
        kernel[k] = 1
        got = await h.run(kernel, samples, tag=f"delta at tap {k}")
        assert np.array_equal(got, samples[k:k + n - K + 1].astype(np.int64)), \
            f"delta at tap {k} did not return x[{k}:{k + n - K + 1}]"
    dut._log.info(f"delta kernels passed for all {K} taps")


@cocotb.test()
async def test_output_count_boundaries(dut):
    """
    Valid-only edges: N samples must produce exactly max(N-K+1, 0) outputs.
    Covers N < K (no output at all), N == K (exactly one), and longer streams.
    """
    h = ConvHarness(dut)
    await h.setup()

    for n in range(1, 3 * K + 3):
        kernel = gm.random_vector_int8(K, seed=SEED + 100 + n)
        samples = gm.random_vector_int8(n, seed=SEED + 200 + n)
        got = await h.run(kernel, samples, settle=8, tag=f"N={n}")
        assert len(got) == gm.expected_output_count(n, K)
    dut._log.info(f"output-count boundaries passed for N = 1..{3 * K + 2}")


@cocotb.test()
async def test_random_trials(dut):
    """NUM_TRIALS randomized convolutions (fixed stream length, random content), bit-exact."""
    assert N_SAMPLES >= K, "N_SAMPLES must be >= K"
    h = ConvHarness(dut)
    await h.setup()

    for t in range(NUM_TRIALS):
        kseed, xseed = SEED + 2 * t, SEED + 2 * t + 1
        kernel = gm.random_vector_int8(K, seed=kseed)
        samples = gm.random_vector_int8(N_SAMPLES, seed=xseed)
        await h.run(kernel, samples, settle=2, tag=f"trial {t} (kernel seed {kseed}, sample seed {xseed})")
        if (t + 1) % 1000 == 0:
            dut._log.info(f"{t + 1}/{NUM_TRIALS} random trials passed")
    dut._log.info(f"PASSED: {NUM_TRIALS}/{NUM_TRIALS} random trials (K={K}, N={N_SAMPLES})")


@cocotb.test()
async def test_random_with_stalls(dut):
    """Random stream lengths (including N < K) with random valid stalls on both input streams."""
    h = ConvHarness(dut, seed=SEED + 999)
    await h.setup()

    for t in range(NUM_STALL_TRIALS):
        n = int(h.rng.integers(1, 3 * K + 11))
        kseed, xseed = SEED + 5000 + 2 * t, SEED + 5000 + 2 * t + 1
        kernel = gm.random_vector_int8(K, seed=kseed)
        samples = gm.random_vector_int8(n, seed=xseed)
        await h.run(kernel, samples, w_stall=0.3, x_stall=0.3, settle=3,
                    tag=f"stall trial {t} (N={n}, seeds {kseed}, {xseed})")
    dut._log.info(f"PASSED: {NUM_STALL_TRIALS} stalled random trials")


@cocotb.test()
async def test_kernel_reload(dut):
    """
    New kernel, same input, no reset in between: results must follow the NEW
    kernel (no stale weights or stale window contents leaking through), both
    with idle gaps and with back-to-back starts as soon as the last output arrives.
    """
    h = ConvHarness(dut)
    await h.setup()

    samples = gm.random_vector_int8(4 * K, seed=SEED + 7)
    kernel_a = gm.ramp_vector_int8(K, start=1)
    kernel_b = gm.ramp_vector_int8(K, start=-(K + 3))
    assert not np.array_equal(kernel_a, kernel_b)

    out_a = await h.run(kernel_a, samples, tag="kernel A")
    out_b = await h.run(kernel_b, samples, tag="kernel B (reload, no reset)")
    out_a2 = await h.run(kernel_a, samples, tag="kernel A again")
    assert not np.array_equal(out_a, out_b), "kernels A and B produced identical outputs; test is vacuous"
    assert np.array_equal(out_a, out_a2), "kernel A results changed after a reload cycle"

    # Tightest legal turnaround: start the next run as soon as the last output was captured.
    for i in range(200):
        kernel = kernel_a if i % 2 == 0 else kernel_b
        n = K + int(h.rng.integers(0, 2 * K + 1))
        samples = gm.random_vector_int8(n, seed=SEED + 9000 + i)
        await h.run(kernel, samples, settle=0, tag=f"back-to-back {i} (N={n})")
    dut._log.info("kernel reload / back-to-back tests passed")


@cocotb.test()
async def test_saturation_extremes(dut):
    """INT8 corner values: the accumulator must never overflow or wrap."""
    h = ConvHarness(dut)
    await h.setup()

    n = 2 * K + 5
    full = lambda length, v: np.full(length, v, dtype=np.int8)
    alt = lambda length: np.array([-128 if i % 2 == 0 else 127 for i in range(length)], dtype=np.int8)

    # (kernel, samples, description, constant expected output or None)
    cases = [
        (full(K, -128), full(n, -128), "(-128)*(-128), largest positive sum", K * 16384),
        (full(K, 127), full(n, -128), "127*(-128), most negative sum", -K * 16256),
        (full(K, -128), full(n, 127), "(-128)*127, most negative sum", -K * 16256),
        (full(K, 127), full(n, 127), "127*127", K * 16129),
        (alt(K), alt(n), "alternating extremes", None),
        (alt(K), full(n, -128), "alternating kernel vs constant -128", None),
        (full(K, 0), full(n, -128), "zero kernel", 0),
        (full(K, -128), full(n, 0), "zero samples", 0),
    ]
    for kernel, samples, desc, const in cases:
        expected = gm.conv1d_int8(samples, kernel)
        assert np.all(np.abs(expected.astype(np.int64)) < 2 ** (ACC_W - 1)), f"{desc}: golden value exceeds ACC_WIDTH"
        got = await h.run(kernel, samples, tag=desc)
        if const is not None:
            assert np.all(got == const), f"{desc}: expected every output == {const}, got {got.tolist()}"
    dut._log.info("saturation / extreme-value tests passed")


@cocotb.test()
async def test_reset_mid_stream(dut):
    """Reset in the middle of a stream: nothing from the aborted run may leak into the next one."""
    h = ConvHarness(dut)
    await h.setup()

    kernel = gm.random_vector_int8(K, seed=SEED + 31)
    samples = gm.random_vector_int8(3 * K, seed=SEED + 32)

    # Start a run, load the kernel, send part of the stream (no x_last), then abort.
    await h._pulse_start()
    await h._stream(dut.w_valid, dut.w_ready, dut.w_data, kernel, name="weights")
    await h._stream(dut.x_valid, dut.x_ready, dut.x_data, samples[:K + 2],
                    last=dut.x_last, assert_last=False, name="partial samples")
    await h.idle(2)
    await h.reset()

    await h.idle(6)
    assert len(h.outputs) == 0, f"outputs appeared after reset: {h.outputs}"

    kernel2 = gm.random_vector_int8(K, seed=SEED + 33)
    samples2 = gm.random_vector_int8(3 * K, seed=SEED + 34)
    await h.run(kernel2, samples2, tag="fresh run after mid-stream reset")
    await h.run(kernel, samples, tag="original kernel after reset")
    dut._log.info("mid-stream reset test passed")
