-- =============================================
-- SECCIÓN 3.2 - CREACIÓN DE LOGINS Y USUARIOS
-- =============================================

USE master;
GO

-- =============================================
-- 1. CREAR LOGINS A NIVEL DE SERVIDOR
-- =============================================

-- Login para la aplicación móvil (Recolectores)
CREATE LOGIN BAMI_Recolector 
WITH PASSWORD = 'BamiRecolector2026!',
     CHECK_EXPIRATION = ON,
     CHECK_POLICY = ON;

-- Login para usuarios operativos
CREATE LOGIN BAMI_Operativo 
WITH PASSWORD = 'BamiOperativo2026!',
     CHECK_EXPIRATION = ON,
     CHECK_POLICY = ON;

-- Login para auditores (solo lectura)
CREATE LOGIN BAMI_Auditor 
WITH PASSWORD = 'BamiAuditor2026!',
     CHECK_EXPIRATION = ON,
     CHECK_POLICY = ON;

-- Login para el coordinador / administrador
CREATE LOGIN BAMI_Coordinador 
WITH PASSWORD = 'BamiCoordinador2026!',
     CHECK_EXPIRATION = ON,
     CHECK_POLICY = ON;
GO

-- =============================================
-- 2. CREAR USUARIOS EN LA BASE DE DATOS BAMI
-- =============================================

USE BAMI;
GO

-- Usuario para la App Móvil (Recolectores)
CREATE USER RecolectorBAMI FOR LOGIN BAMI_Recolector;

-- Usuario Operativo
CREATE USER OperativoBAMI FOR LOGIN BAMI_Operativo;

-- Usuario Auditor
CREATE USER AuditorBAMI FOR LOGIN BAMI_Auditor;

-- Usuario Coordinador
CREATE USER CoordinadorBAMI FOR LOGIN BAMI_Coordinador;
GO
