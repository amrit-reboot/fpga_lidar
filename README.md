# FPGA LiDAR

An FPGA-based LiDAR data-processing design written in Verilog. The project receives LiDAR packet bytes, verifies the packet CRC, extracts twelve distance measurements and the scan angles, calculates the angle for each measurement, and detects objects below a configurable distance threshold.

## Current processing flow

```text
LiDAR byte stream
       |
       v
  lsd02_parser
       |
       +--> 12 distances + start/end angles
       |
       v
 angle_calculator_parallel
       |
       v
   object_detector
```

The parser currently accepts `data_reg` and `data_valid` as inputs. The UART receiver is included as a separate module but is not yet instantiated or connected inside `lidar_top`.

## Repository layout

```text
rtl/
├── calculate_angle.v       Angle interpolation for 12 samples
├── lidar_top.v             Top-level processing module
├── lsd02_parser.v          LiDAR packet parser and CRC checker
├── lsd02_parser_tb.v       Parser simulation testbench
├── object_detector.v       Distance-threshold object detector
└── uart_rx.v               UART receiver module
```

## Top-level interface

`lidar_top` is the main processing module:

| Signal | Direction | Width | Description |
|---|---:|---:|---|
| `clk` | input | 1 | System clock |
| `reset` | input | 1 | Synchronous active-high reset |
| `data_reg` | input | 8 | Received LiDAR byte |
| `data_valid` | input | 1 | One-cycle pulse indicating a valid byte |
| `angles` | output | 192 | Twelve 16-bit angles |
| `angles_valid` | output | 1 | Angle output valid pulse |
| `detection_mask` | output | 12 | One bit per detected object/sample |
| `detection_valid` | output | 1 | Detection output valid pulse |

The packed arrays use sample 0 in bits `[15:0]`, sample 1 in bits `[31:16]`, and so on.

## LiDAR packet format

The parser expects the following packet structure:

```text
0x54 | 0x2C | 44 payload bytes | CRC-8
```

The payload contains twelve distance values, each stored little-endian. The parser extracts:

- Start angle from payload bytes 2 and 3
- Distances from payload bytes 4–5, 7–8, ..., 37–38
- End angle from payload bytes 40 and 41

The CRC is calculated over the header, length byte, and all 44 payload bytes using polynomial `8'h4D`.

## Object detection

The detector marks a sample when its distance is:

```text
0 < distance < 1000 mm
```

The threshold is defined in `rtl/object_detector.v` as:

```verilog
localparam [15:0] THRESHOLD = 16'd1000;
```

## Simulation

Icarus Verilog can be used to compile and run the parser testbench:

```bash
iverilog -g2012 -s tb -o /tmp/fpga_lidar_tb \
    rtl/lds02_parser.v rtl/lsd02_parser_tb.v
vvp /tmp/fpga_lidar_tb
```

Expected result includes:

```text
PASS: Distance = 500 mm
Packet valid
```

To compile the processing top level:

```bash
iverilog -g2012 -s lidar_top -o /tmp/fpga_lidar_sim \
    rtl/calculate_angle.v \
    rtl/lds02_parser.v \
    rtl/lidar_top.v \
    rtl/object_detector.v \
    rtl/uart_rx.v
```

## Next steps

1. Connect `uart_rx` outputs to `lidar_top` so the design can receive a physical UART LiDAR stream.
2. Add a full-system testbench covering the parser, angle calculator, and object detector together.
3. Confirm the UART counter values against the FPGA clock frequency and LiDAR baud rate.
4. Consider pipelining the angle calculation because division by 11 may use significant FPGA resources.
