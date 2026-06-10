library IEEE;
use IEEE.std_logic_1164.all;

entity debounce is
  port(
    clk       : in  std_logic;
    btn_raw   : in  std_logic_vector(4 downto 0);
    btn_pulse : out std_logic_vector(4 downto 0)
  );
end entity debounce;

architecture rtl of debounce is
  constant DEBOUNCE_MAX : integer := 100000;  -- ~1 ms at 100 MHz
  type cnt_arr_t is array (4 downto 0) of integer range 0 to DEBOUNCE_MAX;
  signal cnt        : cnt_arr_t := (others => 0);
  signal clean      : std_logic_vector(4 downto 0) := (others => '0');
  signal prev_clean : std_logic_vector(4 downto 0) := (others => '0');
begin

  process(clk)
  begin
    if rising_edge(clk) then
      -- debounce counters
      for i in 0 to 4 loop
        if btn_raw(i) = clean(i) then
          cnt(i) <= 0;
        else
          if cnt(i) < DEBOUNCE_MAX then
            cnt(i) <= cnt(i) + 1;
          else
            clean(i) <= btn_raw(i);
            cnt(i) <= 0;
          end if;
        end if;
      end loop;

      -- generate one-shot pulse on rising edge of clean(i)
      for i in 0 to 4 loop
        if clean(i) = '1' and prev_clean(i) = '0' then
          btn_pulse(i) <= '1';
        else
          btn_pulse(i) <= '0';
        end if;
      end loop;

      prev_clean <= clean;
    end if;
  end process;

end architecture rtl;