"""
Golden reference model for the weight-stationary INT8 1D convolution accelerator.

Hardware semantics being modeled (see rtl/):
  * kernel w[0..K-1] is loaded once and held (weight-stationary)
  * input samples x[0..N-1] stream through a K-deep sliding window
  * valid-only output: one output per full window, N-K+1 outputs total
    (zero outputs if N < K), no zero-padding at the edges
  * correlation-style sliding dot product, NO kernel flip:

        y[n] = sum_{k=0}^{K-1} x[n+k] * w[k]          n = 0 .. N-K

This is np.correlate(x, w, "valid"), NOT np.convolve (np.convolve flips the
kernel and would silently mismatch the RTL).
"""

import numpy as np

DW = 8  # data width of samples and weights (signed INT8)


def acc_width(k, dw=DW):
    """Accumulator width used by the RTL: ACC_WIDTH = 2*DW + clog2(K) + 2."""
    clog2_k = (k - 1).bit_length()  # ceil(log2(k)) for k >= 1
    return 2 * dw + clog2_k + 2


def expected_output_count(n_samples, k):
    """Number of valid-only outputs for n_samples inputs and a k-tap kernel."""
    return max(n_samples - k + 1, 0)


def _check_int8_vector(name, v):
    v = np.asarray(v)
    if v.ndim != 1:
        raise ValueError(f"{name} must be 1-D, got shape {v.shape}")
    if v.dtype != np.int8:
        raise ValueError(f"{name} must be int8, got {v.dtype}")
    return v


def conv1d_int8(x, w):
    """
    `x`: (`N`,) int8 numpy array (input samples) \n
    `w`: (`K`,) int8 numpy array (kernel taps) \n
    returns: (`N-K+1`,) int32 numpy array, empty if `N < K` \n
    """
    x = _check_int8_vector("x", x)
    w = _check_int8_vector("w", w)
    if len(x) < len(w):
        # np.correlate would swap its arguments here, so guard explicitly.
        return np.zeros(0, dtype=np.int32)
    return np.correlate(x.astype(np.int32), w.astype(np.int32), mode="valid").astype(np.int32)


def conv1d_int8_direct(x, w):
    """Slow, obviously-correct loop version used to cross-check `conv1d_int8`."""
    x = _check_int8_vector("x", x)
    w = _check_int8_vector("w", w)
    n_out = expected_output_count(len(x), len(w))
    out = np.zeros(n_out, dtype=np.int32)
    for i in range(n_out):
        acc = 0
        for j in range(len(w)):
            acc += int(x[i + j]) * int(w[j])
        out[i] = acc
    return out


def random_vector_int8(n, seed=None):
    rng = np.random.default_rng(seed)
    return rng.integers(-128, 128, size=n, dtype=np.int8)


# Helper function for debugging
def ones_vector_int8(n):
    return np.ones(n, dtype=np.int8)


# Helper function for debugging
def ramp_vector_int8(n, start=1):
    """start, start+1, ... wrapped into the int8 range."""
    return (((np.arange(n) + start + 128) % 256) - 128).astype(np.int8)


if __name__ == "__main__":
    # 1. Known-answer test (hand-checked)
    x = np.array([3, 5, 8, 2, 6], dtype=np.int8)
    w = np.array([1, 0, -1], dtype=np.int8)
    expected = np.array([-5, 3, 2], dtype=np.int32)
    result = conv1d_int8(x, w)
    assert np.array_equal(result, expected), f"FAIL: expected {expected}, got {result}"
    print("Known-answer test PASSED")

    # 2. No kernel flip: a delta at tap k must return x shifted by k
    x = random_vector_int8(20, seed=1)
    for k in range(5):
        w = np.zeros(5, dtype=np.int8)
        w[k] = 1
        assert np.array_equal(conv1d_int8(x, w), x[k:k + 16].astype(np.int32)), f"delta tap {k}"
    print("Delta-kernel (no flip) test PASSED")

    # 3. Vectorized model agrees with the direct loop model
    for n, k in [(1, 1), (5, 5), (32, 5), (32, 3), (40, 9), (3, 5), (1, 8)]:
        x = random_vector_int8(n, seed=n * 31 + k)
        w = random_vector_int8(k, seed=n * 17 + k)
        assert np.array_equal(conv1d_int8(x, w), conv1d_int8_direct(x, w)), f"N={n}, K={k}"
    print("Vectorized vs direct model PASSED")

    # 4. Output count formula
    assert expected_output_count(10, 5) == 6
    assert expected_output_count(5, 5) == 1
    assert expected_output_count(4, 5) == 0
    assert len(conv1d_int8(random_vector_int8(4, 0), random_vector_int8(5, 1))) == 0
    print("Output-count test PASSED")

    # 5. Worst-case sums fit in the RTL accumulator width
    for k in range(1, 65):
        worst = k * 128 * 128
        assert worst < 2 ** (acc_width(k) - 1), f"accumulator too narrow for K={k}"
    print("Accumulator-width headroom test PASSED")
    print(f"acc_width(K=3,5,9) = {acc_width(3)}, {acc_width(5)}, {acc_width(9)}")
