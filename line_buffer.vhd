library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity line_buffer is
    generic (
        LROW: integer := 16;
        TAB: integer := 4;
        N_CHAR: integer := 32;
        N_BITS: integer := 5;
        BYTE: integer := 7
    );
    Port (
        clk, reset : in std_logic;
        str : in std_logic_vector(N_CHAR * BYTE - 1 downto 0);
        row_done : in std_logic;
        complete_line : out std_logic_vector(BYTE * LROW - 1 downto 0) := (others => '0')
    );
end line_buffer;

architecture Behavioral of line_buffer is
    signal printed : std_logic_vector(N_BITS - 1 downto 0) := (others => '0');
    signal char_line : std_logic_vector(BYTE * LROW - 1 downto 0);
    signal col : integer range 0 to LROW - 1 := 0;
    signal line_done : std_logic := '0';
    signal current_row : integer range 0 to 1 := 0; -- Track which row we're filling
begin
    process(clk)
        variable parsed_char : std_logic_vector(BYTE - 1 downto 0);
        variable parse_begin : integer range 0 to str'left;
        variable loc : integer range 0 to N_CHAR - 1;
        variable needed_space : integer range 1 to 4;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                col <= 0;
                printed <= (others => '0');
                char_line <= (others => '0');
                complete_line <= (others => '0');
                line_done <= '0';
                current_row <= 0; -- Start with row 0
            elsif line_done = '0' then
                -- Adjust loc based on the current row
                loc := to_integer(unsigned(printed)) + (current_row * LROW);
                
                parse_begin := loc * BYTE;
                if parse_begin + BYTE - 1 <= str'high then
                    parsed_char := str(parse_begin + BYTE - 1 downto parse_begin); -- LSB to MSB
                    printed <= printed + 1;
                else
                    parsed_char := "0100000"; -- Space if out of bounds
                end if;

                if parsed_char = "0000000" or parsed_char = "0001010" then
                    char_line(char_line'left downto col * BYTE) <= (others => '0');
                    col <= 0;
                    line_done <= '1';
                elsif parsed_char = "0001001" then
                    needed_space := TAB - (col mod TAB);
                    if LROW > col + needed_space then
                        char_line((col + needed_space) * BYTE - 1 downto col * BYTE) <= (others => '0');
                        col <= col + needed_space;
                    else
                        char_line(char_line'left downto col * BYTE) <= (others => '0');
                        line_done <= '1';
                        col <= 0;
                    end if;
                else
                    char_line((col + 1) * BYTE - 1 downto col * BYTE) <= parsed_char;
                    col <= col + 1;
                end if;

                if col >= LROW - 1 or loc >= N_CHAR - 1 then
                    col <= 0;
                    line_done <= '1';
                end if;
            elsif row_done = '1' then
                complete_line <= char_line;
                char_line <= (others => '0');
                line_done <= '0';
                col <= 0;
                if current_row = 0 then
                    printed <= std_logic_vector(to_unsigned(LROW, printed'length)); -- Start at position 16 for second row
                    current_row <= 1; -- Move to row 1
                else
                    printed <= (others => '0'); -- Reset to position 0 for next cycle
                    current_row <= 0; -- Reset to row 0
                end if;
            end if;
        end if;
    end process;
end Behavioral;