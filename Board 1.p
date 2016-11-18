/******************************************************************************
 * Copyright 2016 Specialized Solutions LLC
 *
 * Title to the Materials (contents of this file) remain with Specialized
 * Solutions LLC.  The Materials are copyrighted and are protected by United
 * States copyright laws.  Copyright notices cannot be removed from the
 * Materials.
 *
 * See the file titled "Specialized Solutions LLC License Agreement.txt"
 * that has been distributed with this file for further licensing details.
 *
 * Default Badge Script for DefCon 24
 *
 * This demo shows off many features of the PAWN language and the QCM
 * subsystem.
 *
 *****************************************************************************/

new simulation_mode = 0		/* 	0 == OFF
								1 == ON */
new current_led_mode = 0	/*  0x00 == OFF
								0x10 == RED
								0x20 == GREEN
								0x30 == BLUE */
show_menu()
{
    state menu
}

input_switch_left_debounce() <menu>
{

}

input_switch_right_debounce() <menu>
{
/*	Start and Stop the CAN network traffic generator */
	if (simulation_mode == 0)
	{
		simulation_mode = 1
		printf("Simulation Started\n")
	}
	else
	{
		simulation_mode = 0
		printf("Simulation Stopped\n");
	}
}

led_handler(rx_msg[QCM_CAN_MSG])
{
	new new_color = 0;

	if (rx_msg.data[0] == 0x00)
	{
		new_color = 0x0;
	}
	else if(rx_msg.data[0] == 0x10)
	{
		new_color = 0b1111100000000000
	}
	else if(rx_msg.data[0] == 0x20)
	{
		new_color = 0b0000011111100000
	}
	else if(rx_msg.data[0] == 0x30)
	{
		new_color = 0b0000000000011111
	}

   	qcm_led_set(LED_FRONT_BOTTOM, new_color)
   	qcm_led_set(LED_FRONT_TOP, new_color)
  	qcm_led_set(LED_REAR_BOTTOM, new_color)
  	qcm_led_set(LED_REAR_TOP, new_color)
}

start_demo()
{
	qcm_timer_start(TIMER_1,5000,true)	/* 0x100 CAN Frame Timer */
}


@timer1() <menu>
{
	current_led_mode = current_led_mode + 0x10
	if (current_led_mode > 0x30)
		current_led_mode = 0x00

	new tx_msg[QCM_CAN_MSG]

	tx_msg.id = 0x100
	tx_msg.dlc = 0x8
	tx_msg.data[0] = current_led_mode
	tx_msg.data[1] = 0xAA
	tx_msg.data[2] = 0xAA
	tx_msg.data[3] = 0xAA
	tx_msg.data[4] = 0xAA
	tx_msg.data[5] = 0xAA
	tx_msg.data[6] = 0xAA
	tx_msg.data[7] = 0xAA

	printf("Transmitting CAN 0 Message\n")
	qcm_can_tx(CAN0, tx_msg);
	led_handler(tx_msg)
}


stop_demo()
{
	qcm_timer_stop(TIMER_0)
	qcm_timer_stop(TIMER_1)
	qcm_led_set(LED_FRONT_BOTTOM, 0)
	qcm_led_set(LED_FRONT_TOP, 0)
	qcm_led_set(LED_REAR_BOTTOM, 0)
	qcm_led_set(LED_REAR_TOP, 0)
	mutation_mode = 0
}


/******************************************************************************
 * Default state handlers
 *****************************************************************************/

input_switch_right_debounce() <>
{

}

input_switch_left_debounce() <>
{

}

@timer1() <>
{

}


/******************************************************************************
 * Switch debounce routines
 *****************************************************************************/
@gpio_input_switch_right()
{
    /* start debounce timer */
    qcm_timer_start(TIMER_2,50,false)
}

@gpio_input_switch_left()
{
    /* start debounce timer */
    qcm_timer_start(TIMER_3,50,false)
}

@timer2()
{
    if (qcm_gpio_get_input(GPIO_INPUT_SWITCH_RIGHT))
    {
        /* button has been released - call new function to handle debounced input */
        input_switch_right_debounce()
    }
}

@timer3()
{
    if (qcm_gpio_get_input(GPIO_INPUT_SWITCH_LEFT))
    {
        /* button has been released - call new function to handle debounced input */
        input_switch_left_debounce()
    }
}

@can0_rx0(rx_msg[QCM_CAN_MSG])	/* Handler for all CAN 0 messages */
{
	printf("CAN0 Msg Received: %x, %d, %d : ", rx_msg.id, rx_msg.is_extended, rx_msg.dlc)
}


/******************************************************************************
 * Main routine (initilization)
 *****************************************************************************/
main()
{
	sleep 1000

	state menu

	/* Initialize the Display */
	qcm_display_init()
	qcm_display_backlight(75)

	/* Initialize Switches */
	qcm_gpio_configure_handler(GPIO_INPUT_SWITCH_LEFT, GPIO_EVENT_HIGH)
	qcm_gpio_configure_handler(GPIO_INPUT_SWITCH_RIGHT, GPIO_EVENT_HIGH)

	/* Initialize CAN Interfaces */
	qcm_can_init(CAN0, 500000);

	show_menu()
	start_demo()
}

