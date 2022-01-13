# ARC4-Cracker
## 1 Introduction: 
This is an ARC4 Cracking Circuit that is implemented using SystemVerilog and DE1-SoC to decrypt ciphers with a key of smaller than or equal to 3-byte of length. 
## 2 Overview (Hierarchical Design):
### Module Instantiation Tree
```bash

top_arc4 (top module)
├── doublecrack[dc] (Parallel cracking module)
│   ├─  ct_mem [c1,c2] (Ciphertext sub-memorry modlue for c1 and c2)
│   ├── pt_mem [pt] (Plaintext memorry modlue)
│   └── crack [c1, c2] (Crack Module #1 and #2)
│      ├── pt_mem [pt1] (Plaintext memorry modlue for ac4)
│      └── arc [arc4] (ARC4 Module)
│          ├── s_mem [s] (S Memorry)
│          ├── init [INIT] (Module for initializing)
│          ├── ksa  [KSA] （Key-Scheduling algorithm module）
|          ├── prga [PRGA] (Pseudo-Random generation algorithm module)
|          └── fsm  [FSM]  (FSM used to control the dataflow within ARC4 )
├── sseg [hex0, hex1, hex2, hex3, hex4, hex5] (HEX display module)
└── ct_mem [ct](Ciphertext memorry modlue)

```

