LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY fetch_stage IS
    PORT (
        conditional_jumps : IN STD_LOGIC;
        ret_or_rti_signal : IN STD_LOGIC;
        r_src1_from_excute : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        mem_out : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        same_pc_write_disable : IN STD_LOGIC;
        freeze_signal : IN STD_LOGIC;
        int_signal : IN STD_LOGIC;
        invalid_memory : IN STD_LOGIC;
        empty_stack : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        index_bit : IN STD_LOGIC;
        memory_clk : IN STD_LOGIC;
        clk : IN STD_LOGIC;
        memory_reset : IN STD_LOGIC;
        freeze_instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        is_immediate : IN STD_LOGIC;

        pc_from_fetch : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        instruction_bits_output : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        immediate_bits_output : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)

    );
END fetch_stage;

ARCHITECTURE Behavioral OF fetch_stage IS

    -- Signal to connect to the output of the pc_unit component
    SIGNAL pc_unit_result_signal : STD_LOGIC_VECTOR (2 DOWNTO 0);

    -- Signals to connect to memory_entity
    SIGNAL write_data_signal : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL write_en_signal : STD_LOGIC := '0';
    -- Internal signals to connect with the memory component
    SIGNAL instruction_memory_read_data_signal : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Internal signal for read_data from memory
    SIGNAL im_0_internal : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Internal signal for IM[0]
    SIGNAL im_1_internal : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Internal signal for IM[1]
    SIGNAL im_2_internal : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Internal signal for IM[2]
    SIGNAL im_3_internal : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Internal signal for IM[3]
    SIGNAL im_4_internal : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Internal signal for IM[4]

    SIGNAL pc_read_data_signal : STD_LOGIC_VECTOR (15 DOWNTO 0);
    SIGNAL incremented_pc_signal : STD_LOGIC_VECTOR (15 DOWNTO 0);

    SIGNAL first_mux_output_signal, second_mux_output_signal, third_mux_output_signal : STD_LOGIC_VECTOR (0 DOWNTO 0);

    SIGNAL pc_input_signal : STD_LOGIC_VECTOR (15 DOWNTO 0);
    ----------------------------------------------------------------------------------------------------------------------
    -- -- Component declaration for pc_unit
    -- COMPONENT pc_unit
    --     PORT (
    --         same_pc_write_disable : IN STD_LOGIC;
    --         freeze_signal : IN STD_LOGIC;
    --         int_signal : IN STD_LOGIC;
    --         invalid_memory : IN STD_LOGIC;
    --         empty_stack : IN STD_LOGIC;
    --         reset : IN STD_LOGIC;
    --         index_bit : IN STD_LOGIC;
    --         result_of_pc_unit : OUT STD_LOGIC_VECTOR (2 DOWNTO 0)
    --     );
    -- END COMPONENT;

    -- -- Component Declaration
    -- COMPONENT memory_entity
    --     PORT (
    --         clk : IN STD_LOGIC;
    --         reset : IN STD_LOGIC;
    --         address : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
    --         write_data : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
    --         read_data : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
    --         write_en : IN STD_LOGIC
    --     );
    -- END COMPONENT;

    -- -- Component declaration for pipeline_register (used as program counter register)
    -- COMPONENT pipeline_register
    --     GENERIC (
    --         WIDTH : INTEGER := 32 -- Set width to 32 bits for the program counter
    --     );
    --     PORT (
    --         clk : IN STD_LOGIC;
    --         flush : IN STD_LOGIC;
    --         data_in : IN STD_LOGIC_VECTOR (WIDTH - 1 DOWNTO 0);
    --         data_out : OUT STD_LOGIC_VECTOR (WIDTH - 1 DOWNTO 0)
    --     );
    -- END COMPONENT;

    -- COMPONENT mux_2_input
    --     GENERIC (
    --         size : INTEGER := 8 -- Size of each input (bit-width)
    --     );
    --     PORT (
    --         input_0 : IN STD_LOGIC_VECTOR (size - 1 DOWNTO 0); -- First input
    --         input_1 : IN STD_LOGIC_VECTOR (size - 1 DOWNTO 0); -- Second input
    --         sel : IN STD_LOGIC; -- Selection signal (0 or 1)
    --         result : OUT STD_LOGIC_VECTOR (size - 1 DOWNTO 0) -- Output
    --     );
    -- END COMPONENT;

    -- -- Instantiate the add_one component to increment the Program Counter (PC)
    -- COMPONENT add_one
    --     GENERIC (
    --         width => 16 -- Assuming 16-bit width for the PC
    --     );
    --     PORT (
    --         input : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- Input PC value
    --         output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0) -- Output (incremented PC)
    --     );
    -- END COMPONENT;

    -- -- Component declaration for mux_8_input
    -- COMPONENT mux_8_input
    --     GENERIC (
    --         size : INTEGER := 16 -- Width of the inputs
    --     );
    --     PORT (
    --         input_0 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         input_1 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         input_2 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         input_3 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         input_4 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         input_5 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         input_6 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         input_7 : IN STD_LOGIC_VECTOR(size - 1 DOWNTO 0);
    --         sel : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- Selection signal
    --         result : OUT STD_LOGIC_VECTOR(size - 1 DOWNTO 0) -- Selected output
    --     );
    -- END COMPONENT;

    ----------------------------------------------------------------------------------------------------------------------------
BEGIN

    -- Instantiate the pc_unit component
    pc_unit_instance : ENTITY work.pc_unit
        PORT MAP(
            same_pc_write_disable => same_pc_write_disable,
            freeze_signal => freeze_signal,
            int_signal => int_signal,
            invalid_memory => invalid_memory,
            empty_stack => empty_stack,
            reset => reset,
            index_bit => index_bit,
            result_of_pc_unit => pc_unit_result_signal -- Connect output to signal
        );

    -- Instantiate the memory_entity component
    memory_inst : ENTITY work.memory_entity
        PORT MAP(
            clk => memory_clk, -- Connect clock
            reset => memory_reset, -- Connect reset signal
            address => pc_read_data_signal, -- Connect address (PC)
            write_data => write_data_signal, -- Write data (not used in fetch stage) /////from the assembler
            read_data => instruction_memory_read_data_signal, -- Connect output to signal 
            write_en => write_en_signal, -- Disable write in fetch stage  /////from the assembler

            -- Connect internal signals to IM[0] to IM[4] outputs
            im_0 => im_0_internal,
            im_1 => im_1_internal,
            im_2 => im_2_internal,
            im_3 => im_3_internal,
            im_4 => im_4_internal
        );

    -- Instantiate the pipeline_register as the program counter register (pc_register)
    pc_register_inst : ENTITY work.pipeline_register
        GENERIC MAP(
            WIDTH => 16 -- 16-bit width for the program counter
        )
        PORT MAP(
            clk => clk, -- Connect the clock signal
            flush => '0', -- as the one who controlling here is the mux before it
            data_in => pc_input_signal, -- Connect the new PC value input 
            data_out => pc_read_data_signal -- Connect the output to the current PC value
        );

    -- Instantiate the add_one component to increment the PC value
    add_one_inst : ENTITY work.add_one
        PORT MAP(
            input => pc_read_data_signal, -- Input the current PC value
            output => incremented_pc_signal -- Output the incremented PC value as a signal
        );

    -- Instantiate the first mux_2_input component
    mux_inst_1 : ENTITY work.mux_2_input
        GENERIC MAP(
            size => 1
        )
        PORT MAP(
            input_0 => incremented_pc_signal, -- incremented PC value as input_0
            input_1 => r_src1_from_excute, -- Alternative address as input_1
            sel => conditional_jumps, -- Selection signal to choose between inputs
            result => first_mux_output_signal
        );

    -- Instantiate the second mux_2_input component
    mux_inst_2 : ENTITY work.mux_2_input
        GENERIC MAP(
            size => 1
        )
        PORT MAP(
            input_0 => first_mux_output_signal,
            input_1 => mem_out,
            sel => ret_or_rti_signal, -- Selection signal to choose between inputs
            result => second_mux_output_signal
        );
    -- Instantiate the mux_8_input component
    mux_8_inst : ENTITY work.mux_8_input
        GENERIC MAP(
            size => 16 -- 16-bit wide inputs
        )
        PORT MAP(
            input_0 => second_mux_output_signal,
            input_1 => pc_read_data_signal,
            input_2 => im_0_internal,
            input_3 => im_1_internal,
            input_4 => im_2_internal,
            input_5 => im_3_internal,
            input_6 => im_4_internal,
            input_7 => second_mux_output_signal,
            sel => pc_unit_result_signal,
            result => pc_input_signal
        );

    demux_inst : ENTITY work.demux_unit
        GENERIC MAP(
            size => 16 -- Set the width of input/output signals
        )
        PORT MAP(
            output_0 => instruction_bits_output, -- Connect to output 0
            output_1 => immediate_bits_output, -- Connect to output 1

            same_pc_write_disable => same_pc_write_disable, -- Connect control signals
            freeze_signal => freeze_signal,

            freeze_instruction => freeze_instruction,
            instruction_memory_result_input => instruction_memory_read_data_signal,

            is_immediate => is_immediate, -- Immediate mode selection signal
            reset => reset
        );

    pc_from_fetch <= pc_read_data_signal;

END Behavioral;