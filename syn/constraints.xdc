# constraints.xdc
# Clock constraint only. The design is synthesized out-of-context (no board),
# so there are no PACKAGE_PIN / IOSTANDARD assignments.
# 10.000 ns period = 100 MHz target.

create_clock -name clk -period 10.000 [get_ports clk]