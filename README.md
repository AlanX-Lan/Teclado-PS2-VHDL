# Teclado PS/2 en VHDL

## Descripción

Este proyecto implementa la interfaz para un teclado PS/2 utilizando VHDL, el objetivo del proyecto es leer las entradas del teclado PS/2 y mostrar los caracteres en un display de 7 segmentos.

## Características

- **Lectura de Teclado PS/2**: Capacidad para leer y procesar entradas de un teclado PS/2.
- **Desentrelazado**: Implementación de un filtro de rebotes para limpiar las señales del teclado.
- **Conversión a Display de 7 Segmentos**: Convierte los códigos de tecla en valores hexadecimal y los muestra en un display de 7 segmentos.

## Archivos Incluidos

- `ps2_keyboard.vhd`: Código VHDL que implementa la lógica para la lectura del teclado PS/2.
- `debounce.vhd`: Módulo que implementa el filtro de rebotes.
- `hex_to_7seg.vhd`: Módulo que convierte valores hexadecimal a display de 7 segmentos.

## Uso

Para usar este proyecto, sigue estos pasos:

1. **Abrir el Proyecto**: Abre el archivo principal del proyecto en el entorno de desarrollo Altera Quartus.
2. **Asignar Pines**: Usa las herramientas de Quartus para asignar los pines.
3. **Programar**: Programa el diseño en la FPGA y conecta el teclado PS/2.
