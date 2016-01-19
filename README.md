# FIFO_HDL
mini FIFO  verilog script 

mini FIFO verilog 源码.

说明：

<<<有两个模块>>>：

    (1) WRITE DSIZE -> READ DSIZE
    
    (2) WRITE DSIZE*NSIZE -> READ DIZE  (NSIZE 为2的指数倍，否则会发生不可预料的事情，呵呵，应该支持其他非2^x的数，我只是没试过而已)
    
<<<每个模块都带TB文件>>> 我并没有做完完整测试!!!

<<<纯verilog 搭建>>> 用于需要小容量的FIFO的时候（深度小于32,我已经写死，要想支持更大的深度，要给一下源码)

<<<异步FIFO>>> 我已经在工程上使用第二个模块。


--@--Young--@--

