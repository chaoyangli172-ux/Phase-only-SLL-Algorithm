# Phase-only-SLL-Algorithm
*Running **Initial_edition_code.m** produces results similar to those shown below.*
<img width="1394" height="983" alt="image" src="https://github.com/user-attachments/assets/6fafd707-60cf-45f1-91ea-a3f1148ca9a7" />
<img width="1394" height="983" alt="image" src="https://github.com/user-attachments/assets/f931ef07-b81d-4f70-b4a2-3e5a91143a77" />
<img width="1394" height="983" alt="image" src="https://github.com/user-attachments/assets/80fdc76d-71f1-4a08-a060-128ac04e4e1f" />  

This repository presents a MATLAB-based phase-only sidelobe level (SLL) optimization algorithm and documents the design process.  

# HFSS Simulation Verification
<img width="539" height="469" alt="image" src="https://github.com/user-attachments/assets/daa56b30-bc68-4be3-baad-36aa86f1bb36" />   

*Figure 1. A simple 256-element array used for full-wave verification in HFSS.*  
<img width="817" height="471" alt="image" src="https://github.com/user-attachments/assets/852ae10d-a891-4f53-ac57-aef3d0500d08" />  

*Figure 2. Sidelobe level optimized from -10.44 dB to -14.02 dB with only 0.29 dB main beam degradation at a scan angle of φ = 0°, θ = 60°.*  
<img width="798" height="469" alt="image" src="https://github.com/user-attachments/assets/0965b4dd-a63d-418b-8540-27f0a0848114" />  

*Figure 3. Three-dimensional radiation pattern after optimization at a scan angle of φ = 0°, θ = 60°.*  
<img width="971" height="536" alt="image" src="https://github.com/user-attachments/assets/2b3e553c-bbb0-43ea-a146-1a538ce41430" />

*Figure 4. SLL = -11.34 dB in sine space before optimization at a scan angle of φ = 45°, θ = 60°.*  
<img width="1128" height="623" alt="image" src="https://github.com/user-attachments/assets/915d9171-5de0-42a3-9053-d6bde8e8be57" />  

*Figure 5. SLL = -17.35 dB with only 0.269 dB main beam degradation in sine space after optimization at a scan angle of φ = 45°, θ = 60°.*    

**Why Does the Optimized SLL Vary with Different Scan Angles?**
Due to the scanning characteristics of phased arrays, the number of effective radiating elements involved in beam steering varies with the azimuth angle. Therefore, the achievable sidelobe level after optimization is also dependent on the scan direction.  

For this array configuration, the best sidelobe performance (approximately -17 dB) is achieved at φ = 45°, 135°, 225°, and 315°, while relatively higher sidelobe levels (approximately -14 dB) occur at φ = 0°, 90°, 180°, and 270°.  

# Features
1. MATLAB implementation  
2. Phase-only synthesis  
3. Simulated Annealing optimization  
4. Low sidelobe level optimization  
5. Benchmark comparison with an optimized implementation 
6. Detailed algorithm design notes  

# Introduction  

Active phased-array antennas have been widely used in satellite communication (SATCOM) systems in recent years. According to antenna theory, the sidelobe level (SLL) of a uniformly excited array is approximately -13 dB at boresight and may increase to around -10 dB or -9 dB when the scan angle reaches 60°.  

Since each element (or subarray) in an active phased-array antenna is equipped with an independent phase shifter and power amplifier, amplitude tapering usually reduces the effective isotropic radiated power (EIRP). Therefore, phase-only synthesis is often preferred for sidelobe suppression.  

This repository demonstrates a baseline MATLAB implementation based on Simulated Annealing (SA) for phase-only low SLL optimization. However, the baseline implementation suffers from extremely long computation time and high memory consumption.  

I subsequently developed an optimized implementation that significantly improves computational efficiency while maintaining equivalent optimization results. The computational time was reduced from approximately **one month** to about **two hours** on an NVIDIA P2000 GPU.  

Memory usage was reduced from **36,313 KB** to **304 KB** (or by a similar percentage when implemented on FPGA flash memory).  

<img width="601" height="52" alt="image" src="https://github.com/user-attachments/assets/4b53123e-fec2-415b-a069-3c92322e3a68" />  
*Figure 1. Memory usage comparison between the baseline implementation and the optimized implementation.*  

The optimized implementation is not publicly available due to intellectual property considerations and potential commercial value.  

# Design Process

1. Initially, a Genetic Algorithm (GA) was investigated. However, due to its relatively slow convergence for this optimization problem, Simulated Annealing (SA) was adopted instead.  

2. It was observed that the maximum sidelobe does not necessarily appear on the principal scan plane when φ is neither 0° nor 90°. Therefore, the sine-space representation (uv coordinates in the code), which was introduced in antenna theory, was adopted for sidelobe searching.  

3. To accurately identify the sidelobe level, the first local minima on both sides of the main beam are detected. The region between these minima is considered the main lobe, while the highest remaining peak is treated as the maximum sidelobe level.  

4. The optimization methods used to overcome the above-mentioned computational challenges are intentionally omitted from this repository.  

# Why Does the Baseline Algorithm Take So Long?  

The long computation time is mainly caused by the complexity of the optimization problem itself rather than the implementation language.  

For practical phased-array antennas, phase-only optimization needs to be performed independently for different operating frequencies and scan angles because no closed-form analytical solution exists.  

For example, when optimizing an antenna operating at multiple frequencies, the algorithm repeatedly performs the following procedures:  

* Optimize the phase distribution using Simulated Annealing.  
* Evaluate the radiation pattern.  
* Search for the maximum sidelobe level.  
* Repeat the optimization process for each scan angle.  
* Repeat again for each operating frequency.  

As a result, the total computational workload grows rapidly with the number of frequencies, scan angles, and optimization iterations. In practical antenna design scenarios, the baseline implementation may require several weeks to complete the entire optimization process.  

The optimized implementation reduces redundant computation and memory usage while maintaining equivalent optimization performance. The detailed implementation is intentionally omitted due to intellectual property considerations.  
