# 8_BIT_CIPHER_DESIGN_AND_UVM_TB

**Key points of Encryption Design:**
1) PRNG (pseudo random generator) is used to encrypt the input data.
2) PRNG is implemented using an LFSR, updated on every clock edge.
3) Interface is used to connect the design and UVM testbench
4) Freq of clock = 100 Mhz
5) Encrypt the input data by XORing the input data with prng.
   Decrypt the same data using the same prng.
   enc_data_out[7:0] <= prng_now[7:0] ^ din_dly[7:0];
   dec_data_out[7:0] <= (prng_now[7:0] ^ din_dly[7:0]) ^ prng_now[7:0];
7) DUT outputs both encrypted and decrypted data along with the PRNG used.
   
**Key points of UVM Test bench:**
1) Implemented sequencer to send the 3 data's to the design
2) The driver updates data_in and encrypt_en to the DUT every 3 positive edges.
3) The monitor samples below for  every 3 positive edges and sends it to the scoreboard.
a) data_in
b) enc_data_out
c) dec_data_out
d) prng_used
4) In scoreboard, compute the encrypted & decrypted data using the sampled data_in and prng_used.
   If the encrypted output from design and UVM testbench is same, the test is passed.
   Otherwise the test is failed. 

**EDA link:**

https://www.edaplayground.com/x/KdxX

**Snippet of signals:**

<img width="716" height="364" alt="image" src="https://github.com/user-attachments/assets/b62a5024-5620-4de3-a965-2f134abc2dda" />

**Snippet of logs:**

<img width="898" height="412" alt="image" src="https://github.com/user-attachments/assets/fdef4365-55d0-4a98-b3b4-10294d5d55b3" />
