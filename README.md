# ARC4-Cracker
## 1 Introduction: 
This is an ARC4 Cracking Circuit that is implemented using SystemVerilog and DE1-SoC to decrypt ciphers with a key of smaller than or equal to 3-byte of length. 
## 2 Overview:
### 2.1 Module Instantiation Tree (Hierarchical):
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
### 2.2 FSM Algorithm Overview:
1. Load the ciphertext to be cracked into ct_mem[ct]
2. Press Key 3 to rest
3. Copy the memoerry content from ct_mem[ct] to both ct_mem [c1,c2] submodules respectively
4. Enable both crack c1 and c2 modules [C1 will search thru all even number keys while C2 will go thru all odd number possibilities]
5. C1 and C2 will follow the identical steps from 6-8
6. Initialize the s_mem using module init
7. Perform the KSA using module ksa
8. Implement PRGA to find the plaintext（If the resulting number from any PRGA operation is a non-ascii character (PRGA is performed on every character stored in ct_mem), terminate the current cracking process immediately, increment the key number by 2 and go back to step 6 unless all keys have been searched then proceed to step 9 ）
10. Depending on whether there is a solution and which crack module has cracked the key, we will copy the plaintext from the corresponding pt_mem submodule to the main pt_meme module, pt_mem[pt].
11. Halt and Indicate the result using LEDR and HEX displays.

### 2.3 Result Display:
If the key found is 'h123456 then the displays should read “123456” left-to-right when the board is turned so that the switch bank and the button keys are towards you. The displays should be blank while the circuit is computing (i.e., you should only set them after you have found a key), and should display “------” if you searched through the entire key space but no possible 24-bit key resulted in a cracked message (as defined above). T
