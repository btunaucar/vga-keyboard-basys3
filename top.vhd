library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
  port (
    clk100  : in  std_logic;                 -- 100 MHz
    reset_n : in  std_logic;                 -- BTN_C, active-low
    SW      : in  std_logic_vector(6 downto 0);  -- 7-bit ASCII
    BTN     : in  std_logic_vector(3 downto 0);  -- {Enter, Clear, Save, Load}
    VGA_HS  : out std_logic;
    VGA_VS  : out std_logic;
    VGA_R   : out std_logic_vector(3 downto 0);
    VGA_G   : out std_logic_vector(3 downto 0);
    VGA_B   : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of top is
  constant LROW   : integer := 16;    -- columns per row
  constant N_CHAR : integer := 32;    -- total slots (16×2)
  constant BYTE   : integer := 7;     -- bits per char

  -- Debounce
  signal btn_raw    : std_logic_vector(4 downto 0);
  signal btn_pulse  : std_logic_vector(4 downto 0);
  signal enter_p, clear_p, save_p, load_p : std_logic;

  -- active-high reset for submodules
  signal rst   : std_logic := '0';

  -- packed screen str
  signal str_bus : std_logic_vector(N_CHAR*BYTE-1 downto 0);

begin
  -- invert the incoming BTN_C
  rst <= not reset_n;
  btn_raw <= rst & BTN;

  -- 1 ms debounce + one-shot
  deb: entity work.debounce
    port map (
      clk       => clk100,
      btn_raw   => btn_raw,
      btn_pulse => btn_pulse
    );
  enter_p <= btn_pulse(0);
  clear_p <= btn_pulse(1);
  save_p  <= btn_pulse(2);
  load_p  <= btn_pulse(3);

  -- char buffer (32 slots)
  buf: entity work.char_buffer
    generic map (
      N_CHAR => N_CHAR,
      BYTE   => BYTE
    )
    port map (
      clk     => clk100,
      reset_n => rst,
      enter_p => enter_p,
      clear_p => clear_p,
      save_p  => save_p,
      load_p  => load_p,
      sw_in   => SW,
      str_out => str_bus
    );

  -- VGA engine
  vg: entity work.vga
    generic map (
      LROW   => LROW,
      N_CHAR => N_CHAR,
      BYTE   => BYTE
    )
    port map (
      clk    => clk100,
      reset  => reset_n,
      str    => str_bus,
      hsync  => VGA_HS,
      vsync  => VGA_VS,
      r      => VGA_R,
      g      => VGA_G,
      b      => VGA_B
    );
end architecture;