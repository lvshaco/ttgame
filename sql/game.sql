-- MySQL dump 10.13  Distrib 5.1.73, for redhat-linux-gnu (x86_64)
--
-- Host: localhost    Database: lxj
-- ------------------------------------------------------
-- Server version	5.1.73

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `x_role`
--

DROP TABLE IF EXISTS `x_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_role` (
  `roleid` int(11) NOT NULL AUTO_INCREMENT COMMENT 'auto increment id in the database',
  `acc` varchar(64) NOT NULL DEFAULT '' COMMENT 'acc',
  `gmlevel` int(11) NOT NULL DEFAULT 0 COMMENT '玩家详细信息大字段',
  `info` blob COMMENT '玩家详细信息大字段',
  PRIMARY KEY (`roleid`),
  UNIQUE `acc` (`acc`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='role';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_item`
--

DROP TABLE IF EXISTS `x_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_item` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'items',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='item';
/*!40101 SET character_set_client = @saved_cs_client */;
