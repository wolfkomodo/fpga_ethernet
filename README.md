# fpga_ethernet
Ethernet stack for interfacing in RMII with Ethernet PHY of Nexys4 DDR FPGA. This work was done as part of a larger project, always_comm, which is a was an FPGA-based video streaming device. Because that code is under the MIT GitHub enterprise (@ https://github.mit.edu/akshay-a/always_comm), I'm moving the Ethernet stack that I independently built to a public repo.

The code will need a top_level.sv file to be synthed by Vivado. This top_level can instantiate the 2 networking modules and pass any data stream into them to be sent via Ethernet. The modules implement Ethernet, IPv4, and UDP.
