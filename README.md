**Summary**

We attempt to implement of Extropic's Stoichastic Processing Unit in Verilog and build a basic 8 bit model in Altium. Our architecture follows Extropic's Pater, "An efficient probabilistic hardware architecture for diffusion-like models" by Andraž Jelinčič et al (https://arxiv.org/pdf/2510.23972).

**Brief Background**

The Extropic architecture samples complex probability distributions efficiency by breaking the distribution into a product of many simple distributions over binary variables that are easy to sample. These simple distributions are modelled by a quadratic energy over a 70x70 grid of binary nodes where a percentage of nodes are latent hidden states and the rest are visible nodes representing the input data. The energy of the entire network is formally defined as $E(x) = -\beta \left(  \sum_{i \ne j} x_i J_{ij} x_j  + \sum_{i} h_i x_i \right)$ where $x_i \in \{-1, +1\}.$.

For each node, we only create connections with nodes at (x+a,y+b), (x−b,y+a), (x−a,y−b), (x+b,y−a). The paper suggests using (a, b) = (0,1), (4,1), (9,10). They call this G12 connectivity; it captures short, medium and long range interactions. They also define other connectivity patterns which you can read more about in Appendix C of the paper. If we label every even index node as black and every odd index node as white, each node's energy would only depend on nodes of opposite colour. This speeds up the sampling of the graph from O(L^2) to O(2), as we can update each colour of nodes in parallel at a time.

Since we model a joint distribution, each 70x70 grid models $P(x_t | x_{t-1})$. To condition the distribution on $x_{t-1}$, we 

<img width="713" height="475" alt="image" src="https://github.com/user-attachments/assets/11e3a7e4-c78b-415e-9cfd-6a18c4bfae59" />




Will use 8 bit weights and biases and keep it small so we can print it as a PCB.


My idea is to do the following:

Top level processor (orchestrates EBM sampling and training) --> Boltzmann Machine Grid (64 boltzmann visible nodes in grid pattern )  --> weight memory (i.e store and load the weights for the current time step)

