.. _module_spi_master:

=====================
SPI Master Module
=====================

.. contents:: In this document
    :backlinks: none
    :depth: 3

This module provides functions to read and write data using the SPI protocol.

Those functions are used in the SPI encoders :ref:`REM 14 Encoder Module <module_rem_14>` itself used by :ref:`REM 16MT Encoder Module <module_rem_16mt>` to read and write data from the encoders.

The functions should always run over an **IFM Tile** so it can access the ports to
your SOMANET IFM device.

.. cssclass:: github

  `See Module on Public Repository <https://github.com/synapticon/sc_sncn_motorcontrol/tree/master/module_spi_master>`_


How to use
==========

.. important:: We assume that you are using :ref:`SOMANET Base <somanet_base>` and your app includes the required **board support** files for your SOMANET device.

1. First, add all the :ref:`SOMANET Motion Control <somanet_motion_control>` modules to your app Makefile.

    ::

        USED_MODULES = configuration_parameters module_adc module_spi_master lib_bldc_torque_control module_board-support module_hall_sensor module_utils module_position_feedback module_pwm module_incremental_encoder module_biss_encoder module_encoder_rem_14 module_serial_encoder module_shared_memory module_spi_master module_watchdog 

    .. note:: Not all modules will be required, but when using a library it is recommended to include always all the contained modules.
          This will help solving internal dependency issues.

2. Include the SPI master header **spi_master.h** in your app.

3. Instantiate the ports for the SPI.

     It needs a ``SPIPorts`` structure containing two clock blocks and 4 1-bit ports for SPI.

4. At your IF2 tile, You can use the functions to read or write SPI data.
    .. code-block:: c

         #include <CoreC2X.bsp>   			//Board Support file for SOMANET Core C22 device 
        #include <Drive1000-rev-c4.bsp>     //Board Support file for SOMANET IFM DC100 device 
                                            //(select your board support files according to your device)

        // 2. Include the SPI Master header **spi_master.h** in your app.
        #include <spi_master.h>
        
        // 3.Instantiate the ports for the SPI.
        SPIPorts spi_ports = SOMANET_DRIVE_SPI_PORTS;

        int main(void)
        {
            par
            {
                on tile[IF2_TILE]:
                {                    
                    // 4. Use the functions to read and write SPI data.
                    // initialize the master
                    spi_master_init(spi_ports.spi_interface, DEFAULT_SPI_CLOCK_DIV);
                    
                    // read SPI data
                    slave_select(*spi_ports.slave_select);
                    short data_in = spi_master_in_short(spi_ports.spi_interface);
                    slave_deselect(*spi_ports.slave_select);
                    
                    //write SPI data
                    short data = 0xab
                    slave_select(*spi_ports.slave_select);
                    spi_master_out_short(spi_ports.spi_interface, data);
                    slave_deselect(*spi_ports.slave_select);
                }
            }

            return 0;
        }

API
===

Definitions
-----------

.. doxygendefine:: DEFAULT_SPI_CLOCK_DIV
.. doxygendefine:: SPI_MASTER_MODE
.. doxygendefine:: SPI_MASTER_SD_CARD_COMPAT

Types
-----

.. doxygenstruct:: spi_master_interface
.. doxygenstruct:: SPIPorts

Functions
--------

.. doxygenfunction:: spi_master_init
.. doxygenfunction:: spi_master_shutdown
.. doxygenfunction:: spi_master_in_byte
.. doxygenfunction:: spi_master_in_short
.. doxygenfunction:: spi_master_in_word
.. doxygenfunction:: spi_master_in_buffer
.. doxygenfunction:: spi_master_out_byte
.. doxygenfunction:: spi_master_out_short
.. doxygenfunction:: spi_master_out_word
.. doxygenfunction:: spi_master_out_buffer

