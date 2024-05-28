-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 29-05-2024 a las 00:58:24
-- Versión del servidor: 11.2.0-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `camicandy`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `nombre` varchar(45) NOT NULL,
  `direccion` varchar(80) NOT NULL,
  `telefono` varchar(16) NOT NULL,
  `cedula` varchar(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `migrations`
--

CREATE TABLE `migrations` (
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Volcado de datos para la tabla `migrations`
--

INSERT INTO `migrations` (`name`) VALUES
('20240425_00_init.js');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `nombre` varchar(20) NOT NULL,
  `fecha_de_vencimiento` date NOT NULL,
  `cantidad_disponible` int(3) NOT NULL,
  `imagen` longblob DEFAULT NULL,
  `precio_en_dolares` decimal(4,2) NOT NULL,
  `unidad_de_medicion` varchar(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `rif` varchar(12) NOT NULL,
  `direccion` varchar(80) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sesiones`
--

CREATE TABLE `sesiones` (
  `id` int(11) NOT NULL,
  `token` text NOT NULL,
  `valido_hasta` timestamp NOT NULL,
  `usuarios_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sesiones`
--

INSERT INTO `sesiones` (`id`, `token`, `valido_hasta`, `usuarios_id`) VALUES
(1, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Mjk5MDMwODksImlkIjoxLCJpYXQiOjE3MTQ4NDA4MDh9.yF5GZgfu6yjs26eO71L9HWaRbBnnge1tsrkav3nAeC4', '2026-01-01 03:59:59', 1),
(2, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Mjk4Nzc5ODcsImlkIjoyLCJpYXQiOjE3MTQ4NDA5MDd9.6MWQmUdL2QDTU0q6RtjbhUpu5wuOp-QB9dD1qxoId38', '2026-01-01 03:59:59', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `transacciones`
--

CREATE TABLE `transacciones` (
  `id` int(11) NOT NULL,
  `marca_de_tiempo` timestamp NOT NULL,
  `importe_en_dolares` decimal(5,2) DEFAULT NULL,
  `tasa_bcv` decimal(6,2) UNSIGNED NOT NULL,
  `clientes_id` int(11) DEFAULT NULL,
  `proveedores_id` int(11) DEFAULT NULL,
  `usuarios_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='* Falta añadir un trigger o un CHECK para revisar que sólo clientes_id o proveedores_id es NULL pero no ambos\\\\n* También falta verificar que sólo el administrador puede registrar una compra\\\\n* columna monto: Si es positivo la transacción fue una venta a un cliente, si es negativo fue una compra a un proveedor';

--
-- Disparadores `transacciones`
--
DELIMITER $$
CREATE TRIGGER `check_admin_compra` BEFORE INSERT ON `transacciones` FOR EACH ROW BEGIN
    IF NEW.importe_en_dolares < 0 AND NEW.usuarios_id NOT IN (SELECT id FROM usuarios WHERE rol = 'administrador') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Solo el administrador puede registrar una compra.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `validar_clientes_proveedores` BEFORE INSERT ON `transacciones` FOR EACH ROW BEGIN
    IF (NEW.clientes_id IS NULL AND NEW.proveedores_id IS NULL) OR (NEW.clientes_id IS NOT NULL AND NEW.proveedores_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: clientes_id y proveedores_id no pueden ser ambos NULL o ambos diferentes de NULL.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `validar_monto` BEFORE INSERT ON `transacciones` FOR EACH ROW BEGIN
    IF (NEW.importe_en_dolares > 0 AND
    NEW.proveedores_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El importe de una compra no puede ser positivo.';
    ELSEIF (NEW.importe_en_dolares < 0 AND NEW.clientes_id IS NOT NULL) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El importe de una venta no puede ser negativo.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `transacciones_tiene_productos`
--

CREATE TABLE `transacciones_tiene_productos` (
  `transacciones_id` int(11) NOT NULL,
  `productos_id` int(11) NOT NULL,
  `cantidad` int(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `transacciones_tiene_productos`
--
DELIMITER $$
CREATE TRIGGER `actualizar_stock_monto` AFTER INSERT ON `transacciones_tiene_productos` FOR EACH ROW BEGIN
    DECLARE total_amount DECIMAL(10, 2);
    
    -- Actualizar stock del producto
    UPDATE productos 
    SET cantidad_disponible = cantidad_disponible - NEW.cantidad 
    WHERE id = NEW.productos_id;
    
    -- Calcular el monto total de la transacción
    SET total_amount = (SELECT SUM(cantidad * precio_en_dolares) FROM transacciones_tiene_productos 
                        JOIN productos ON transacciones_tiene_productos.productos_id = productos.id
                        WHERE transacciones_tiene_productos.transacciones_id = NEW.transacciones_id);
    
    -- Actualizar el importe de la transacción
    UPDATE transacciones
    SET importe_en_dolares = total_amount
    WHERE id = NEW.transacciones_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `cedula` varchar(12) NOT NULL,
  `nombre` varchar(45) NOT NULL,
  `rol` enum('empleado','administrador') NOT NULL,
  `hash_de_contrasena` varchar(60) NOT NULL,
  `pregunta_seguridad` enum('¿Cuándo es tu cumpleaños?','¿A qué secundaria fuiste?','¿Cómo se llamaba tu mamá?','¿Cuál es tu postre favorito?') NOT NULL,
  `respuesta_seguridad` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `cedula`, `nombre`, `rol`, `hash_de_contrasena`, `pregunta_seguridad`, `respuesta_seguridad`) VALUES
(1, '29903089', 'juan', 'administrador', '$2b$10$mVwVDKUIArIjnW9zpNSj5.NUzkjBGNFTKXEVpM9bGHZ/dbSiVhWa2', '¿Cuál es tu postre favorito?', '$2b$10$mVwVDKUIArIjnW9zpNSj5.NUzkjBGNFTKXEVpM9bGHZ/dbSiVhWa2'),
(2, '29877987', 'samuel', 'empleado', '$2b$10$V1rms6bjuDgK2wMStrN53uOheLkNQXXEd4ZCUP5e2CpAbC8jzLKFi', '¿Cuál es tu postre favorito?', '$2b$10$V1rms6bjuDgK2wMStrN53uOheLkNQXXEd4ZCUP5e2CpAbC8jzLKFi');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`),
  ADD UNIQUE KEY `cedula_UNIQUE` (`cedula`);

--
-- Indices de la tabla `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`name`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idproveedores_UNIQUE` (`id`),
  ADD UNIQUE KEY `rif_UNIQUE` (`rif`);

--
-- Indices de la tabla `sesiones`
--
ALTER TABLE `sesiones`
  ADD PRIMARY KEY (`id`,`usuarios_id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`),
  ADD UNIQUE KEY `token_UNIQUE` (`token`) USING HASH,
  ADD KEY `fk_sesiones_usuarios1_idx` (`usuarios_id`);

--
-- Indices de la tabla `transacciones`
--
ALTER TABLE `transacciones`
  ADD PRIMARY KEY (`id`,`usuarios_id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`),
  ADD KEY `fk_transacciones_clientes1_idx` (`clientes_id`),
  ADD KEY `fk_transacciones_proveedores1_idx` (`proveedores_id`),
  ADD KEY `fk_transacciones_usuarios1_idx` (`usuarios_id`);

--
-- Indices de la tabla `transacciones_tiene_productos`
--
ALTER TABLE `transacciones_tiene_productos`
  ADD PRIMARY KEY (`transacciones_id`,`productos_id`),
  ADD KEY `fk_transacciones_has_productos_productos1_idx` (`productos_id`),
  ADD KEY `fk_transacciones_has_productos_transacciones1_idx` (`transacciones_id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idusuarios_UNIQUE` (`id`),
  ADD UNIQUE KEY `cedula_UNIQUE` (`cedula`);

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `sesiones`
--
ALTER TABLE `sesiones`
  ADD CONSTRAINT `fk_sesiones_usuarios1` FOREIGN KEY (`usuarios_id`) REFERENCES `usuarios` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `transacciones`
--
ALTER TABLE `transacciones`
  ADD CONSTRAINT `fk_transacciones_clientes1` FOREIGN KEY (`clientes_id`) REFERENCES `clientes` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_transacciones_proveedores1` FOREIGN KEY (`proveedores_id`) REFERENCES `proveedores` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_transacciones_usuarios1` FOREIGN KEY (`usuarios_id`) REFERENCES `usuarios` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `transacciones_tiene_productos`
--
ALTER TABLE `transacciones_tiene_productos`
  ADD CONSTRAINT `fk_transacciones_has_productos_productos1` FOREIGN KEY (`productos_id`) REFERENCES `productos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_transacciones_has_productos_transacciones1` FOREIGN KEY (`transacciones_id`) REFERENCES `transacciones` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
