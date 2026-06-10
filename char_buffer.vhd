library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity char_buffer is
  generic (
    N_CHAR : integer := 32;  -- 16×2
    BYTE   : integer := 7
  );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;       -- active-low
    enter_p : in  std_logic;
    clear_p : in  std_logic;
    save_p  : in  std_logic;
    load_p  : in  std_logic;
    sw_in   : in  std_logic_vector(BYTE-1 downto 0);
    str_out : out std_logic_vector(N_CHAR*BYTE-1 downto 0)
  );
end entity;

architecture rtl of char_buffer is
  type mem_t is array(0 to N_CHAR-1) of std_logic_vector(BYTE-1 downto 0);
  signal buff   : mem_t := (others => (others => '0'));
  signal snap   : mem_t := (others => (others => '0'));
  signal ptr    : integer range 0 to N_CHAR := 0;
  signal ptr_s  : integer range 0 to N_CHAR := 0;
begin
  -- pack onto output bus
  pack: for i in 0 to N_CHAR-1 generate
    str_out((i+1)*BYTE-1 downto i*BYTE) <= buff(i);
  end generate;

  process(clk, reset_n)
    variable temp_buff : mem_t;
  begin
    if reset_n = '0' then
      buff  <= (others => (others => '0'));
      snap  <= (others => (others => '0'));
      ptr   <= 0;
      ptr_s <= 0;
    elsif rising_edge(clk) then
      -- Default: set all slots to ASCII space
      temp_buff := (others => "0100000");  -- ASCII space

      -- Copy existing buffer content up to ptr
      for i in 0 to N_CHAR-1 loop
        if i < ptr then
          temp_buff(i) := buff(i);
        end if;
      end loop;

      -- Apply control signals
      if clear_p = '1' then
        temp_buff := (others => (others => '0'));
        ptr <= 0;
      elsif save_p = '1' then
        snap <= buff;
        ptr_s <= ptr;
      elsif load_p = '1' then
        temp_buff := snap;
        ptr <= ptr_s;
      elsif enter_p = '1' then
        if ptr < N_CHAR then
          temp_buff(ptr) := sw_in;
          ptr <= ptr + 1;
        end if;
      end if;

      -- Update buff with the modified temporary buffer
      buff <= temp_buff;
    end if;
  end process;
end architecture;