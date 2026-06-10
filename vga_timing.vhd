library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_timing is
  port(
    clk        : in  std_logic;  -- 25 MHz
    reset      : in  std_logic;
    row_done   : out std_logic;
    row        : out std_logic_vector(4 downto 0);
    col        : out std_logic_vector(6 downto 0);
    charrow    : out std_logic_vector(3 downto 0);
    charcol    : out std_logic_vector(2 downto 0);
    hsync      : out std_logic;
    vsync      : out std_logic;
    display_on : out std_logic
  );
end entity;

architecture rtl of vga_timing is
  signal hc, vc: unsigned(9 downto 0) := (others=>'0');
begin
  sync: process(clk)
  begin
    if rising_edge(clk) then
      if reset='1' then
        hc <= (others=>'0'); vc <= (others=>'0');
      else
        if hc = 799 then
          hc <= (others=>'0');
          if vc = 524 then vc <= (others=>'0'); else vc <= vc + 1; end if;
        else
          hc <= hc + 1;
        end if;
      end if;
    end if;
  end process;

  hsync      <= '0' when hc>=656 and hc<752 else '1';
  vsync      <= '0' when vc>=490 and vc<492 else '1';
  display_on <= '1' when hc<640 and vc<480 else '0';
  row_done   <= '1' when hc=639 and vc(3 downto 0)="1111" else '0';
  
  -- text row 0 for vc<16*30, row 1 for vc<32 etc.
  row <= std_logic_vector(resize(vc(8 downto 4),5));
  col <= std_logic_vector(resize(hc(9 downto 3),7));
  charrow <= std_logic_vector(vc(3 downto 0));
  charcol <= std_logic_vector(hc(2 downto 0));
end architecture;
