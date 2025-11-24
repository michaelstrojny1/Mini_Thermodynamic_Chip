**Summary**

This repository is work in progress. We attempt to:

(1) Build a simple version of Extropic's Stoichastic Processing Unit in Verilog, Xschem, Magic VLSI.

(2) Build an Altium (PCB) version. This will use Zener Avalanche noise for the pbit (RNG) instead of CMOS capacitive node noise since the capacitance of PCB sized components (+ traces) is too high for the latter

Our architecture follows Extropic's Paper, "An efficient probabilistic hardware architecture for diffusion-like models" by Andraž Jelinčič et al (https://arxiv.org/pdf/2510.23972) [1].

**Very high level summary of proposed structure**

A processor connected to

(1) EBM Weight/Bias Memory (SRAM) 

(2) Registers for previous state of EBM ($\vecX_{t-1}$) and other needed temporary values like clock 

(3) interface to 70×70 grid of (analog) Pbits which recieve the weights and biases and output the bit flip for each node

**Brief Background**

The Extropic architecture samples complex probability distributions efficiency by breaking the distribution into a product of many simple distributions over binary variables that are easy to sample. These simple distributions are modelled by a quadratic energy over a 70x70 grid of binary nodes where a percentage of nodes are hidden states for computational purposes (i.e a latent state) and the rest are visible nodes. For each node, we create connections with nodes at (x+a,y+b), (x−b,y+a), (x−a,y−b), (x+b,y−a). The Extropic paper [1] suggests using 3 sets of connections (a, b) = (0,1), (4,1), (9,10). They call this G12 connectivity; it captures short, medium and long range interactions respectively. They also define other connectivity patterns which you can read more about in Appendix C of the paper. If we label every even index node as black and every odd index node as white, each node's energy would only depend on nodes of opposite colour. This speeds up the sampling of the graph from O(L^2) to O(2), as we can update each colour of nodes in parallel at a time. Since we model a joint distribution, each 70x70 grid should model $P(x_n | x_{n-1})$; we condition the visible nodes on $x_{n-1}$ by connecting $x_{n}$ and $x_{n-1}$ with 1-1 coupling with learned weights. We thus define the networks energy as: $E(x) = - \left(  \sum_{i \ne j} x_i J_{ij} x_j  + \sum_{i} h_i x_i + \sum_{i} A_i x_i x_{i, n-1} \right)$ where $x_i$ is either 1 or -1. This represents one of the distributions forming our joing distribution $P(x_N) = \prod^T_0 P(x_n | x_{t-n})$. We sample $P(x_N)$ by sequentially sampling each timesteps 70x70 network and feeding the output $x_n$ as $x_{n-1}$ into the next timsteps network. Note that from now, we will flip the notation; $u_0$ represents the final distribution and $x_N$ represents the starting distribution or first product in the joint distribution which is pure gaussian noise.

<img width="561" height="526" alt="image" src="https://github.com/user-attachments/assets/45b7ebfa-414b-46f4-813d-cde0564bd3e1" />

We train the 70x70 network at each time step individually. Like a diffusion model, we add noise to training data using a markov chain; we define the chain such that the data at the final timestep $T$ is pure gaussian noise. We use this markov chain to generate data for time step; we then train each timesteps network on this data to reverse the addition of noise at it's respective time step. For instance, at timestep 5, we would train the model to output $u_{4}$ when fed $u_{5}$). This training is done via the Contrastive Divergence algorthm. See the image below from [1] showing an illustration of the joint distribution sampling (Image A) and a high level hardware implemenentation where each "block" is our 70x70 network (Image B):

<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/11e3a7e4-c78b-415e-9cfd-6a18c4bfae59" />

This section details the physical mechanism by which the Extropic architecture generates and samples the thermal randomness required for its probabilistic computations.

## PBit (EBM Samping)

<img width="750" height="388" alt="image" src="https://github.com/user-attachments/assets/9143b9de-6d19-452e-8802-f72def92c3b0" />

A MOSFET has three parallel capacitances; gate capacitance, source-drain capacitance, and capacitance between the wire connected to the source and drain. For a capacitive node, $V_{rms, noise} = \sqrt{\frac{k_B T}{C_{total}}}$. High capacitance leads to weaker noise and works against us; we want small MOSFETS with very short wiring to reduce total capacitance. 

The noisy voltage  must be converted from a analog to digital. This is done using a comparator which triggers at a clock signal and outputs 1 or 0 based on that instant's voltage noise. We have one **P-bit** per **Node** in the EBM. We "bias" the P-bit based on that nodes incoming weights and biases. The result of the P-Bit is the state of the node in the next time step. See the image below for a schematic of the P-bit. Each conductance is the magnitude of each term in the sum inside the node-update sigmoid $P(x_i = 1 | x) = \sigma\left(2\beta \left(\sum_{j \neq i} J_{ij} x_j + h_i\right)\right)$, and the voltage sign is the term sign. This creates a bias voltage (V_b) at the end of the parallel network which biases the mean of the gaussian noise source connected to it to favour either a 1 or 0 flip when fed into a comparator. There wasn't a schematic for the noise generator in the paper [1], so we will connect V_b to the gates of a parallel PMOS and NMOS in the subthreshold region. These two MOSFETS are in parallel with a 3rd NMOS with constant gate voltage. They add negative or positive bias current (respectively) to the constant "mean" current from the 3rd NMOS. The three MOSFETS all feed into a comparator. There is capacitive node noise in the MOSFETs, creating randomness in the current generated; we would maximize noise in the 3rd MOSFET (minimizing capacitance) and minimize noise in the other two.

<img width="711" height="443" alt="image" src="https://github.com/user-attachments/assets/d5930401-a44e-49f9-90e7-461f9478bc3c" />


**References**

[1] Andraž Jelinčič et al, "An efficient probabilistic hardware architecture for diffusion-like models" (https://arxiv.org/pdf/2510.23972)
