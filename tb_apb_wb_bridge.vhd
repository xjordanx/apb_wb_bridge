library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;         -- For file I/O
--use IEEE.STD_LOGIC_TEXTIO.ALL;  -- For writing std_logic_vector as text
use work.io_utils.all;

entity tb_apb_wb_bridge is
end tb_apb_wb_bridge;

architecture sim of tb_apb_wb_bridge is
    -- APB interface signals
    signal apb_pclk_i    : std_logic := '0';
    signal apb_resetn_i  : std_logic := '0';
    signal apb_addr_i    : std_logic_vector(31 downto 0) := (others => '0');
    signal apb_pselx_i   : std_logic := '0';
    signal apb_penable_i : std_logic := '0';
    signal apb_pwrite_i  : std_logic := '0';
    signal apb_pwdata_i  : std_logic_vector(31 downto 0) := (others => '0');
    signal apb_pready_o  : std_logic;
    signal apb_prdata_o  : std_logic_vector(31 downto 0);
    signal apb_pslverr_o : std_logic;
    signal apb_int_o     : std_logic;
    
    -- Wishbone interface signals (internal connections)
    signal wb_clk        : std_logic;
    signal wb_rst        : std_logic;
    signal wb_cyc        : std_logic;
    signal wb_stb        : std_logic;
    signal wb_we         : std_logic;
    signal wb_adr        : std_logic_vector(7 downto 0);
    signal wb_dat_o      : std_logic_vector(7 downto 0);  -- From bridge (for write)
    signal wb_dat_i      : std_logic_vector(7 downto 0);  -- To bridge (read data from target)
    signal wb_ack        : std_logic;
    signal wb_int        : std_logic;  -- From target

    component apb_wb_bridge
         generic (
             HOST_ADDR_WIDTH : integer ;
             SLAVE_DATA_WIDTH : integer ;
             HOST_DATA_WIDTH : integer ;
             SLAVE_ADDR_WIDTH : integer ;
             ADDRESSING_MODE : string
         );
         port (
             -- System CLK/RST
             apb_pclk_i     : in  std_logic;
             apb_resetn_i   : in  std_logic;
             -- APB Signals
             apb_addr_i     : in  std_logic_vector(HOST_ADDR_WIDTH-1 downto 0);
             apb_pselx_i    : in  std_logic;
             apb_penable_i  : in  std_logic;
             apb_pwrite_i   : in  std_logic;
             apb_pwdata_i   : in  std_logic_vector(HOST_DATA_WIDTH-1 downto 0);
             apb_pready_o   : out std_logic;
             apb_prdata_o   : out std_logic_vector(HOST_DATA_WIDTH-1 downto 0);
             apb_pslverr_o  : out std_logic;

             -- Wishbone Signals
             wb_clk_o    : out std_logic;
             wb_rst_o    : out std_logic;
             wb_cyc_o    : out std_logic;
             wb_stb_o    : out std_logic;
             wb_we_o     : out std_logic;
             wb_adr_o    : out std_logic_vector(SLAVE_ADDR_WIDTH-1 downto 0);
             wb_dat_o    : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
             wb_dat_i    : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
             wb_ack_i    : in  std_logic;

             -- Interrupts
             apb_int_o   : out std_logic;
             wb_int_i    : in std_logic
         );
    end component;

  -- Dummy RAM for testing the WB side.
    component wb_target_mem
         generic (
            SLAVE_ADDR_WIDTH : integer ;
            SLAVE_DATA_WIDTH : integer
         );
         port (
            wb_clk_i : in std_logic;
            wb_rst_i : in std_logic;
            wb_cyc_i : in std_logic;
            wb_stb_i : in std_logic;
            wb_we_i  : in std_logic;
            wb_adr_i : in std_logic_vector(SLAVE_ADDR_WIDTH-1 downto 0);
            wb_dat_i : in std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0); -- Data from master (for writes)
            wb_dat_o : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0); -- Data to master (for reads)
            wb_ack_o : out std_logic;
            wb_int_o : out std_logic  -- Interrupt output
         );
    end component;

begin
    --------------------------------------------------------------------
    -- Instantiate the apb_wb_bridge with the specified generic values.
    --------------------------------------------------------------------
    uut_bridge: apb_wb_bridge generic map (
         HOST_ADDR_WIDTH  => 32,
         HOST_DATA_WIDTH  => 32,
         SLAVE_DATA_WIDTH => 8,
         SLAVE_ADDR_WIDTH => 8,
         ADDRESSING_MODE  => "byte"
      )
      port map (
         apb_pclk_i    => apb_pclk_i,
         apb_resetn_i  => apb_resetn_i,
         apb_addr_i    => apb_addr_i,
         apb_pselx_i   => apb_pselx_i,
         apb_penable_i => apb_penable_i,
         apb_pwrite_i  => apb_pwrite_i,
         apb_pwdata_i  => apb_pwdata_i,
         apb_pready_o  => apb_pready_o,
         apb_prdata_o  => apb_prdata_o,
         apb_pslverr_o => apb_pslverr_o,
         wb_clk_o      => wb_clk,
         wb_rst_o      => wb_rst,
         wb_cyc_o      => wb_cyc,
         wb_stb_o      => wb_stb,
         wb_we_o       => wb_we,
         wb_adr_o      => wb_adr,
         wb_dat_o      => wb_dat_o,
         wb_dat_i      => wb_dat_i,
         wb_ack_i      => wb_ack,
         apb_int_o     => apb_int_o,
         wb_int_i      => wb_int
      );

    --------------------------------------------------------------------
    -- Instantiate the Wishbone target memory.
    --------------------------------------------------------------------
    uut_target: wb_target_mem generic map (
         SLAVE_ADDR_WIDTH => 8,
         SLAVE_DATA_WIDTH => 8
      )
      port map (
         wb_clk_i => wb_clk,
         wb_rst_i => wb_rst,
         wb_cyc_i => wb_cyc,
         wb_stb_i => wb_stb,
         wb_we_i  => wb_we,
         wb_adr_i => wb_adr,
         wb_dat_i => wb_dat_o,  -- Data from the bridge (write data)
         wb_dat_o => wb_dat_i,  -- Read data goes back to the bridge
         wb_ack_o => wb_ack,
         wb_int_o => wb_int
      );
      
    --------------------------------------------------------------------
    -- Clock Generation: 50MHz clock (period = 20 ns)
    --------------------------------------------------------------------
    clock_gen: process
    begin
         apb_pclk_i <= '0';
         wait for 10 ns;
         apb_pclk_i <= '1';
         wait for 10 ns;
    end process;
    
    --------------------------------------------------------------------
    -- Reset Generation: Hold apb_resetn low for 5 clock cycles, then high.
    --------------------------------------------------------------------
    reset_gen: process
    begin
         apb_resetn_i <= '0';
         wait for 100 ns;  -- 5 clock cycles @20 ns each = 100 ns
         apb_resetn_i <= '1';
         wait;
    end process;
    
    --------------------------------------------------------------------
    -- APB Host Transaction Process:
    --   1. After reset, write bytes 0x00 through 0xFF using APB write transactions.
    --   2. Wait 12 clock cycles.
    --   3. Read back each location with APB read transactions.
    --   4. Write the read data to a text file (one hex number per line, prefixed with "0x").
    --------------------------------------------------------------------
    apb_host: process
       file file_out : text open write_mode is "readback_data.txt";
       variable line_out : std.textio.line;
       variable read_data : std_logic_vector(7 downto 0);
       variable i         : integer;
    begin
         -- Wait until reset is deasserted.
         wait until apb_resetn_i = '1';
         wait for 20 ns;  -- Wait one clock cycle after reset.

         ----------------------------------------------------------------
         -- Write Phase: Write data values 0x00 through 0xFF.
         ----------------------------------------------------------------
         for i in 0 to 255 loop
             -- Setup phase of APB write.
             apb_addr_i   <= std_logic_vector(to_unsigned(i * 4, 32)); -- Address increments by 4.
             -- Put the data (i) in the LSB of the 32-bit write data.
             apb_pwdata_i <= (others => '0');
             apb_pwdata_i(7 downto 0) <= std_logic_vector(to_unsigned(i, 8));
             apb_pselx_i  <= '1';
             apb_pwrite_i <= '1';
             apb_penable_i<= '0';
             wait until rising_edge(apb_pclk_i);
             
             -- Access phase.
             apb_penable_i <= '1';
             wait until rising_edge(apb_pclk_i);
             -- Wait (if necessary) for the transaction to complete.
             while apb_pready_o /= '1' loop
                 wait until rising_edge(apb_pclk_i);
             end loop;
             
             -- End of transaction: deassert APB control signals.
             apb_pselx_i   <= '0';
             apb_penable_i <= '0';
             apb_pwrite_i  <= '0';
             apb_addr_i    <= (others => '0');
             apb_pwdata_i  <= (others => '0');
         end loop;
         
         -- Wait for 12 clock cycles before starting read transactions.
         for i in 1 to 12 loop
             wait until rising_edge(apb_pclk_i);
         end loop;
         
         ----------------------------------------------------------------
         -- Read Phase: Read back the 256 locations.
         ----------------------------------------------------------------
         for i in 0 to 255 loop
             -- Setup phase for APB read.
             apb_addr_i   <= std_logic_vector(to_unsigned(i * 4, 32));  -- Same addressing scheme.
             apb_pselx_i  <= '1';
             apb_pwrite_i <= '0';
             apb_penable_i<= '0';
             wait until rising_edge(apb_pclk_i);
             
             -- Access phase for read.
             apb_penable_i <= '1';
             wait until rising_edge(apb_pclk_i);
             while apb_pready_o /= '1' loop
                 wait until rising_edge(apb_pclk_i);
             end loop;
             
             -- Capture the read data (from the lower 8 bits).
             read_data := apb_prdata_o(7 downto 0);
             -- Write the data to the output file in hex (e.g. "0x1A").
             write(line_out, string'("0x"));
             work.io_utils.write(line_out, to_integer(read_data), right, 4, hex, false);
             writeline(file_out, line_out);
             
             -- End transaction.
             apb_pselx_i   <= '0';
             apb_penable_i <= '0';
             apb_addr_i    <= (others => '0');
         end loop;
         
         wait;  -- End of simulation.
    end process;

end sim;
