# 8-Tap FIR Filter RTL Design & Verification

An 8-tap low-pass FIR filter implemented in Verilog and verified against a MATLAB golden reference model.

## Highlights

- Designed an 8-tap FIR filter using Verilog RTL.
- Generated Q1.15 coefficients in MATLAB.
- Verified RTL output against a MATLAB reference model.
- Applied a 4-stage pipeline to the MAC datapath, improving Fmax from **33.08 MHz** to **262.12 MHz** (**~7.9× speedup**).
- Synthesized on an Intel Cyclone V FPGA using Quartus Prime.

---

## Specifications

| Item | Value |
|--------|--------|
| Filter Type | 8-Tap Low-Pass FIR |
| Architecture | Direct Form |
| Input Width | 16-bit |
| Output Width | 32-bit |
| Coefficient Format | Q1.15 |
| Sample Rate | 48 kHz |
| Cutoff Frequency | 6 kHz |

---

## Design Evolution

| Version | Description | Fmax |
|----------|----------|----------|
| V1 | Combinational MAC | 33.08 MHz |
| V2 | 4-Stage Pipelined MAC | 262.12 MHz |

Pipeline optimization reduced the critical path and increased operating frequency by approximately **7.9×**, while maintaining a throughput of **1 sample per clock cycle**.

---

## Verification Flow

```text
MATLAB
   │
   ├── input_samples.txt
   ├── expected_output.txt
   │
   ▼
Verilog RTL
   │
   ▼
ModelSim
   │
   └── sim_output.txt
   │
   ▼
Comparison
   │
   ▼
PASS
```

---

## Project Structure

```text
fir-rtl-filter/
│
├── README.md
│
├── rtl/
│   ├── v1_combinational/
│   │   └── fir_filter.v
│   │
│   └── v2_pipelined/
│       └── fir_filter.v
│
├── tb/
│   └── tb_fir_filter.v
│
├── matlab/
│   └── fir_design.m
│
├── sim_results/
│   ├── v1/
│   └── v2/
│
└── synthesis_reports/
    ├── v1_timing_summary.txt
    └── v2_timing_summary.txt
```

---

## How to Run

```bash
vlog fir_filter.v tb_fir_filter.v
vsim tb_fir_filter
run -all
```

Compare `sim_output.txt` against `expected_output.txt`.

Pipeline latency:

- V1: 1 cycle
- V2: 4 cycles

---

## Tools

- Verilog HDL
- MATLAB
- ModelSim
- Intel Quartus Prime

---

## Key Learnings

- Identified the combinational MAC as the Fmax-limiting critical path through Quartus timing analysis.
- Traded 3 cycles of latency for a **7.9× increase in maximum operating frequency**, while maintaining throughput.
- Verified functionality against an independent MATLAB golden model rather than relying solely on waveform inspection.
- Applied a common RTL timing-closure technique used in FPGA and ASIC datapath design: **pipelining**.

---

## Author

**Phan Duy Khanh**

Electronics and Telecommunications Engineering  
University of Science – VNUHCM

GitHub: https://github.com/your-github
LinkedIn: https://linkedin.com/in/your-linkedin
