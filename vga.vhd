library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga is
generic (
    LROW   : integer := 16;
    N_CHAR : integer := 32;
    BYTE   : integer := 7
);
port (
    clk    : in  std_logic;      -- 100 MHz
    reset  : in  std_logic;      -- active-high
    str    : in  std_logic_vector(N_CHAR*BYTE-1 downto 0);
    hsync  : out std_logic;
    vsync  : out std_logic;
    r, g, b: out std_logic_vector(3 downto 0)
);
end entity;

architecture rtl of vga is
    signal pix25    : std_logic;
    signal row_done : std_logic;
    signal row      : std_logic_vector(4 downto 0);
    signal col      : std_logic_vector(6 downto 0);
    signal charrow  : std_logic_vector(3 downto 0);
    signal charcol  : std_logic_vector(2 downto 0);
    signal display  : std_logic;
    signal complete_line : std_logic_vector(BYTE * LROW - 1 downto 0);
    signal cur_char : std_logic_vector(BYTE-1 downto 0);
    signal pixel_on : std_logic;
begin
    -- clock-divider 100?25 MHz
    clkdiv: process(clk, reset)
        variable cnt: unsigned(1 downto 0) := (others => '0');
    begin
        if reset = '1' then
            cnt := (others => '0');
            pix25 <= '0';
        elsif rising_edge(clk) then
            cnt := cnt + 1;
            pix25 <= cnt(1);
        end if;
    end process;

    -- Line buffer
    lb: entity work.line_buffer
    generic map (
        LROW => LROW,
        TAB => 4,
        N_CHAR => N_CHAR,
        N_BITS => 5,
        BYTE => BYTE
    )
    port map (
        clk => pix25,
        reset => reset,
        str => str,
        row_done => row_done,
        complete_line => complete_line
    );

    -- VGA timing
    vg_t: entity work.vga_timing
    port map (
        clk        => pix25,
        reset      => reset,
        row_done   => row_done,
        row        => row,
        col        => col,
        charrow    => charrow,
        charcol    => charcol,
        hsync      => hsync,
        vsync      => vsync,
        display_on => display
    );

    --------------------------------------------------------------------
    -- Latch the next character one half-cycle earlier
    --
    -- On the falling edge of pix25 we grab the new code,
    -- so that on the very next rising_edge at charcol="000"
    -- the correct glyph is selected.
    --------------------------------------------------------------------
    latch_char: process(pix25)
        variable idx: integer range 0 to N_CHAR-1;
    begin
        if falling_edge(pix25) then
            if unsigned(row) < 2 and unsigned(col(3 downto 0)) < 16 then
                idx := to_integer(unsigned(col(3 downto 0))) + (to_integer(unsigned(row)) * LROW);
                if idx < N_CHAR then
                    cur_char <= str(idx*BYTE+BYTE-1 downto idx*BYTE);
                else
                    cur_char <= "0100000";  -- ASCII space
                end if;
            else
                cur_char <= "0100000";  -- ASCII space
            end if;
        end if;
    end process;

    -- Font lookup
    font_i: entity work.char_rom
    port map (
        char_code => cur_char,
        row       => charrow,
        col       => charcol,
        pixel     => pixel_on
    );

    -- RGB output
    rgb_out: process(pix25)
    begin
        if rising_edge(pix25) then
            if display = '1' and pixel_on = '1' and unsigned(row) < 2 and unsigned(col) < 16 then
                r <= "1111"; g <= "1111"; b <= "1111";  -- White
            else
                r <= "0000"; g <= "0000"; b <= "0000";  -- Black
            end if;
        end if;
    end process;
end architecture;