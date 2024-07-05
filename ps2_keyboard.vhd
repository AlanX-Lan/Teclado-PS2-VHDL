LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY ps2_keyboard IS
  GENERIC (
    clk_freq              : INTEGER := 50_000_000;  -- Sistema de frecuencia del reloj en Hz
    debounce_counter_size : INTEGER := 8);          -- Set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
  PORT (
    clk              : IN  STD_LOGIC;                        -- Sistema del reloj
    ps2_clk          : IN  STD_LOGIC;                        -- Señal del reloj del teclado
    ps2_data         : IN  STD_LOGIC;                        -- Señal de datos del teclado
    ps2_code_new     : OUT STD_LOGIC;                        -- Bandera que indica si hay un nuevo código disponible
    ps2_code         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);      -- Código recibido del teclado
    display_hex1     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);      -- Salida para el primer display de 7 segmentos (dígito hexadecimal más significativo)
    display_hex0     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));     -- Salida para el segundo display de 7 segmentos (dígito hexadecimal menos significativo)
END ps2_keyboard;

ARCHITECTURE logic OF ps2_keyboard IS
  SIGNAL sync_ffs     : STD_LOGIC_VECTOR(1 DOWNTO 0);       -- Sincronización de flip-flops para PS/2
  SIGNAL ps2_clk_int  : STD_LOGIC;                          -- Señal de rebote del teclado PS/2
  SIGNAL ps2_data_int : STD_LOGIC;                          -- Señal de datos de rebote del teclado PS/2
  SIGNAL ps2_word     : STD_LOGIC_VECTOR(10 DOWNTO 0);      -- Guarda los datos de palabra del ps2
  SIGNAL error        : STD_LOGIC;                          -- Valida los bits de paridad, start y stop
  SIGNAL count_idle   : INTEGER RANGE 0 TO clk_freq/18_000; -- Counter to determine PS/2 is idle
 
  -- Declare debounce component for debouncing PS2 input signals
  COMPONENT debounce IS
    GENERIC (
      counter_size : INTEGER); -- Debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
    PORT (
      clk    : IN  STD_LOGIC;  -- Input clock
      button : IN  STD_LOGIC;  -- Input signal to be debounced
      result : OUT STD_LOGIC); -- Debounced signal
  END COMPONENT;
  
  -- Declare hex to 7-segment decoder component for displaying hexadecimal digits
  COMPONENT hex_to_7seg IS
    PORT (
      hex_value : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Input hexadecimal value
      seg_out   : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));   -- 7-segment output for display
  END COMPONENT;
  
  -- Instantiate two hex to 7-segment decoder modules
  SIGNAL hex_value0, hex_value1 : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL seg_out0, seg_out1     : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN
  -- Synchronizer flip-flops
  PROCESS(clk)
  BEGIN
    IF (clk'EVENT AND clk = '1') THEN  -- Rising edge of system clock
      sync_ffs(0) <= ps2_clk;           -- Synchronize PS/2 clock signal
      sync_ffs(1) <= ps2_data;          -- Synchronize PS/2 data signal
    END IF;
  END PROCESS;

  -- Debounce PS2 input signals
  debounce_ps2_clk: debounce
    GENERIC MAP (counter_size => debounce_counter_size)
    PORT MAP (clk => clk, button => sync_ffs(0), result => ps2_clk_int);
  debounce_ps2_data: debounce
    GENERIC MAP (counter_size => debounce_counter_size)
    PORT MAP (clk => clk, button => sync_ffs(1), result => ps2_data_int);

  -- Input PS2 data
  PROCESS(ps2_clk_int)
  BEGIN
    IF (ps2_clk_int'EVENT AND ps2_clk_int = '0') THEN    -- Falling edge of PS2 clock
      ps2_word <= ps2_data_int & ps2_word(10 DOWNTO 1);   -- Shift in PS2 data bit
    END IF;
  END PROCESS;
   
  -- Verify that parity, start, and stop bits are all correct
  error <= NOT (NOT ps2_word(0) AND ps2_word(10) AND (ps2_word(9) XOR ps2_word(8) XOR
        ps2_word(7) XOR ps2_word(6) XOR ps2_word(5) XOR ps2_word(4) XOR ps2_word(3) XOR
        ps2_word(2) XOR ps2_word(1)));  

  -- Determine if PS2 port is idle (i.e. last transaction is finished) and output result
  PROCESS(clk)
  BEGIN
    IF (clk'EVENT AND clk = '1') THEN           -- Rising edge of system clock
   
      IF (ps2_clk_int = '0') THEN                 -- Low PS2 clock, PS/2 is active
        count_idle <= 0;                           -- Reset idle counter
      ELSIF (count_idle /= clk_freq/18_000) THEN  -- PS2 clock has been high less than a half clock period (<55us)
          count_idle <= count_idle + 1;            -- Continue counting
      END IF;
     
      IF (count_idle = clk_freq/18_000 AND error = '0') THEN  -- Idle threshold reached and no errors detected
        ps2_code_new <= '1';                                   -- Set flag that new PS/2 code is available
        ps2_code <= ps2_word(8 DOWNTO 1);                      -- Output new PS/2 code
        
        -- Decode the hexadecimal value for displaying in 7-segment displays
        hex_value1 <= ps2_word(7 DOWNTO 4);
        hex_value0 <= ps2_word(3 DOWNTO 0);
      ELSE                                                   -- PS/2 port active or error detected
        ps2_code_new <= '0';                                   -- Set flag that PS/2 transaction is in progress
      END IF;
     
    END IF;
  END PROCESS;
  
  -- Instantiate the hex to 7-segment decoder modules
  display_hex0_inst : hex_to_7seg
    PORT MAP (hex_value => hex_value0, seg_out => seg_out0);
  display_hex1_inst : hex_to_7seg
    PORT MAP (hex_value => hex_value1, seg_out => seg_out1);
  
  -- Connect the outputs of the 7-segment decoders to the display outputs
  display_hex0 <= seg_out0;
  display_hex1 <= seg_out1;
END logic;
