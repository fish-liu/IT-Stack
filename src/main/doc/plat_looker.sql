/*
Navicat MySQL Data Transfer

Source Server         : 127.0.0.1-looker
Source Server Version : 50720
Source Host           : 127.0.0.1:3306
Source Database       : plat_looker

Target Server Type    : MYSQL
Target Server Version : 50720
File Encoding         : 65001

Date: 2020-07-31 18:08:43
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `grow_article`
-- ----------------------------
DROP TABLE IF EXISTS `grow_article`;
CREATE TABLE `grow_article` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `content` varchar(500) DEFAULT NULL,
  `img_ids` varchar(100) DEFAULT NULL,
  `uid` int(11) DEFAULT NULL COMMENT '用户id',
  `cate_id` int(11) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL COMMENT '位置信息',
  `visibility` tinyint(4) DEFAULT NULL COMMENT '可见度',
  `status` tinyint(4) DEFAULT NULL COMMENT '状态（0=正常，1=禁用，2=删除）',
  `publish_time` datetime DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of grow_article
-- ----------------------------
INSERT INTO `grow_article` VALUES ('1', 'test1', '1,2,3', '1', '1', null, '2', '0', '2020-07-08 14:49:55', '2020-07-08 14:49:58', '2020-07-08 14:50:01');
INSERT INTO `grow_article` VALUES ('2', 'test2', '1,2', '1', '2', null, '3', '0', '2020-07-08 14:50:27', '2020-07-08 14:50:31', '2020-07-08 14:50:34');

-- ----------------------------
-- Table structure for `grow_article_tags`
-- ----------------------------
DROP TABLE IF EXISTS `grow_article_tags`;
CREATE TABLE `grow_article_tags` (
  `uid` int(11) DEFAULT NULL COMMENT '用户id',
  `tag_id` int(11) DEFAULT NULL COMMENT '标签tag id',
  `arti_id` int(11) DEFAULT NULL COMMENT '文章id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of grow_article_tags
-- ----------------------------
INSERT INTO `grow_article_tags` VALUES ('1', '1', '1');
INSERT INTO `grow_article_tags` VALUES ('1', '2', '1');
INSERT INTO `grow_article_tags` VALUES ('1', '4', '1');
INSERT INTO `grow_article_tags` VALUES ('1', '2', '2');
INSERT INTO `grow_article_tags` VALUES ('1', '3', '2');
INSERT INTO `grow_article_tags` VALUES ('1', '6', '2');
INSERT INTO `grow_article_tags` VALUES ('1', '9', '2');

-- ----------------------------
-- Table structure for `grow_category`
-- ----------------------------
DROP TABLE IF EXISTS `grow_category`;
CREATE TABLE `grow_category` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(50) DEFAULT NULL COMMENT '分类名称',
  `uid` int(11) DEFAULT NULL COMMENT '用户id（可为空）',
  `status` tinyint(4) DEFAULT NULL COMMENT '分类状态（0=正常，1=禁止）',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  `type` tinyint(4) DEFAULT NULL COMMENT '类型，（0=默认分类（其他）,1=公共分类，2=私有分类）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of grow_category
-- ----------------------------
INSERT INTO `grow_category` VALUES ('1', '其他', null, '0', '2020-07-07 16:26:59', '2020-07-07 16:27:02', '1');
INSERT INTO `grow_category` VALUES ('2', '分类1', null, '0', '2020-07-07 16:28:00', '2020-07-07 16:28:02', '1');
INSERT INTO `grow_category` VALUES ('3', '分类2', null, '0', '2020-07-08 14:11:39', '2020-07-08 14:11:42', '1');
INSERT INTO `grow_category` VALUES ('4', '分类3', null, '0', '2020-07-08 14:12:11', '2020-07-08 14:12:14', '1');
INSERT INTO `grow_category` VALUES ('5', '私有分类1', '1', '0', '2020-07-08 14:12:45', '2020-07-08 14:12:48', '2');
INSERT INTO `grow_category` VALUES ('6', '私有分类2', '1', '0', '2020-07-08 14:13:13', '2020-07-08 14:13:16', '2');

-- ----------------------------
-- Table structure for `grow_category_record`
-- ----------------------------
DROP TABLE IF EXISTS `grow_category_record`;
CREATE TABLE `grow_category_record` (
  `cate_id` int(11) DEFAULT NULL,
  `uid` int(11) DEFAULT NULL,
  `used` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of grow_category_record
-- ----------------------------

-- ----------------------------
-- Table structure for `grow_resources`
-- ----------------------------
DROP TABLE IF EXISTS `grow_resources`;
CREATE TABLE `grow_resources` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `uid` int(11) DEFAULT NULL COMMENT '用户id',
  `name` varchar(50) DEFAULT NULL COMMENT '文件名',
  `path` varchar(100) DEFAULT NULL COMMENT '文件存放路径',
  `suffix` varchar(15) DEFAULT NULL COMMENT '文件后缀',
  `type` tinyint(4) DEFAULT NULL COMMENT '文件类型（头像，图片，视频等）',
  `size` float DEFAULT NULL COMMENT '文件大小',
  `status` tinyint(4) DEFAULT NULL COMMENT '状态',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '最新更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of grow_resources
-- ----------------------------

-- ----------------------------
-- Table structure for `grow_tags`
-- ----------------------------
DROP TABLE IF EXISTS `grow_tags`;
CREATE TABLE `grow_tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(50) DEFAULT NULL COMMENT 'tag名称',
  `uid` int(11) DEFAULT NULL COMMENT '用户id,可以为空，热门标签时该字段为空',
  `group_id` tinyint(4) DEFAULT NULL COMMENT 'tag分组',
  `type` tinyint(4) DEFAULT NULL COMMENT '类型，（1=公共标签，2=私有标签）',
  `status` tinyint(4) DEFAULT NULL COMMENT '状态（0=正常，1=禁用，2=删除）',
  `create_time` datetime DEFAULT NULL COMMENT '添加时间',
  `update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of grow_tags
-- ----------------------------
INSERT INTO `grow_tags` VALUES ('1', '跑步', null, '1', '1', '0', '2020-07-06 15:57:01', '2020-07-08 14:52:10');
INSERT INTO `grow_tags` VALUES ('2', '爬山', null, '1', '1', '0', '2020-07-07 11:15:02', '2020-07-08 14:52:12');
INSERT INTO `grow_tags` VALUES ('3', '骑行', null, '1', '1', '0', '2020-07-07 11:18:57', '2020-07-08 14:52:15');
INSERT INTO `grow_tags` VALUES ('4', '川菜', null, '3', '1', '0', '2020-07-07 11:21:15', '2020-07-07 11:21:43');
INSERT INTO `grow_tags` VALUES ('5', '湘菜', null, '3', '1', '0', '2020-07-08 14:53:49', '2020-07-08 14:53:54');
INSERT INTO `grow_tags` VALUES ('6', '孩子', null, '5', '1', '0', '2020-07-08 14:54:29', '2020-07-08 14:54:31');
INSERT INTO `grow_tags` VALUES ('7', '爱人', null, '5', '1', '0', '2020-07-08 14:54:56', '2020-07-08 14:54:59');
INSERT INTO `grow_tags` VALUES ('8', '唱歌', '1', '0', '2', '0', '2020-07-08 14:55:37', '2020-07-08 14:55:40');
INSERT INTO `grow_tags` VALUES ('9', '撸猫', '1', '0', '2', '0', '2020-07-08 14:56:12', '2020-07-08 14:56:16');

-- ----------------------------
-- Table structure for `grow_users`
-- ----------------------------
DROP TABLE IF EXISTS `grow_users`;
CREATE TABLE `grow_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `name` varchar(50) DEFAULT NULL COMMENT '姓名',
  `password` varchar(30) DEFAULT NULL COMMENT '密码',
  `nick_name` varchar(50) DEFAULT NULL COMMENT '别名',
  `gender` tinyint(4) DEFAULT NULL COMMENT '性别',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `phone` varchar(15) DEFAULT NULL COMMENT '手机号',
  `email` varchar(50) DEFAULT NULL COMMENT '邮箱，可以当做账号',
  `avatar` varchar(100) DEFAULT NULL COMMENT '头像',
  `status` tinyint(4) DEFAULT NULL COMMENT '状态',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of grow_users
-- ----------------------------

-- ----------------------------
-- Table structure for `looker_operation_record`
-- ----------------------------
DROP TABLE IF EXISTS `looker_operation_record`;
CREATE TABLE `looker_operation_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `instance_id` varchar(12) DEFAULT NULL COMMENT '实例id',
  `project_name` varchar(50) DEFAULT NULL COMMENT '项目名',
  `business_line` varchar(20) DEFAULT NULL COMMENT '业务线',
  `framework_version` varchar(50) DEFAULT NULL COMMENT '版本号',
  `ip` varchar(30) DEFAULT NULL COMMENT '服务的ip地址',
  `service_url` varchar(200) DEFAULT NULL COMMENT '服务url',
  `url` varchar(150) DEFAULT NULL COMMENT '请求url',
  `param` varchar(150) DEFAULT NULL COMMENT '请求参数',
  `email` varchar(60) DEFAULT NULL COMMENT '用户邮箱',
  `user_name` varchar(60) DEFAULT NULL COMMENT '用户名',
  `role` varchar(100) DEFAULT NULL COMMENT '角色',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=82 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of looker_operation_record
-- ----------------------------
INSERT INTO `looker_operation_record` VALUES ('4', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/threaddump', '{}', 'xianwei.liu@ucarinc.com', '刘县委', '', '2020-05-07 14:29:35');
INSERT INTO `looker_operation_record` VALUES ('5', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/threaddump', '{}', 'xianwei.liu@ucarinc.com', '刘县委', '', '2020-05-07 14:37:25');
INSERT INTO `looker_operation_record` VALUES ('6', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.uptime', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:57');
INSERT INTO `looker_operation_record` VALUES ('7', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.count', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:57');
INSERT INTO `looker_operation_record` VALUES ('8', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:57');
INSERT INTO `looker_operation_record` VALUES ('9', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:58');
INSERT INTO `looker_operation_record` VALUES ('10', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.live', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:58');
INSERT INTO `looker_operation_record` VALUES ('11', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.peak', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:59');
INSERT INTO `looker_operation_record` VALUES ('12', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.memory.max', '{tag=[area:heap]}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:59');
INSERT INTO `looker_operation_record` VALUES ('13', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:59');
INSERT INTO `looker_operation_record` VALUES ('14', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.memory.used', '{tag=[area:heap]}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:59');
INSERT INTO `looker_operation_record` VALUES ('15', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.daemon', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:20:59');
INSERT INTO `looker_operation_record` VALUES ('16', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.memory.committed', '{tag=[area:heap]}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:21:00');
INSERT INTO `looker_operation_record` VALUES ('17', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.uptime', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:12');
INSERT INTO `looker_operation_record` VALUES ('18', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.count', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:12');
INSERT INTO `looker_operation_record` VALUES ('19', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:12');
INSERT INTO `looker_operation_record` VALUES ('20', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:12');
INSERT INTO `looker_operation_record` VALUES ('21', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.live', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:12');
INSERT INTO `looker_operation_record` VALUES ('22', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.peak', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:12');
INSERT INTO `looker_operation_record` VALUES ('23', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.daemon', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:13');
INSERT INTO `looker_operation_record` VALUES ('24', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:13');
INSERT INTO `looker_operation_record` VALUES ('25', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:15');
INSERT INTO `looker_operation_record` VALUES ('26', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:15');
INSERT INTO `looker_operation_record` VALUES ('27', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.live', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:15');
INSERT INTO `looker_operation_record` VALUES ('28', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.peak', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:15');
INSERT INTO `looker_operation_record` VALUES ('29', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.daemon', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:15');
INSERT INTO `looker_operation_record` VALUES ('30', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:15');
INSERT INTO `looker_operation_record` VALUES ('31', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:17');
INSERT INTO `looker_operation_record` VALUES ('32', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:17');
INSERT INTO `looker_operation_record` VALUES ('33', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.daemon', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:17');
INSERT INTO `looker_operation_record` VALUES ('34', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.peak', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:17');
INSERT INTO `looker_operation_record` VALUES ('35', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.live', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:17');
INSERT INTO `looker_operation_record` VALUES ('36', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:17');
INSERT INTO `looker_operation_record` VALUES ('37', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:20');
INSERT INTO `looker_operation_record` VALUES ('38', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:20');
INSERT INTO `looker_operation_record` VALUES ('39', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.peak', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:20');
INSERT INTO `looker_operation_record` VALUES ('40', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.daemon', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:20');
INSERT INTO `looker_operation_record` VALUES ('41', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.live', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:20');
INSERT INTO `looker_operation_record` VALUES ('42', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:20');
INSERT INTO `looker_operation_record` VALUES ('43', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:24');
INSERT INTO `looker_operation_record` VALUES ('44', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:24');
INSERT INTO `looker_operation_record` VALUES ('45', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:24');
INSERT INTO `looker_operation_record` VALUES ('46', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.daemon', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:24');
INSERT INTO `looker_operation_record` VALUES ('47', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.peak', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:24');
INSERT INTO `looker_operation_record` VALUES ('48', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.threads.live', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:24');
INSERT INTO `looker_operation_record` VALUES ('49', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:24');
INSERT INTO `looker_operation_record` VALUES ('50', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:25');
INSERT INTO `looker_operation_record` VALUES ('51', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:25');
INSERT INTO `looker_operation_record` VALUES ('52', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:26');
INSERT INTO `looker_operation_record` VALUES ('53', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:27');
INSERT INTO `looker_operation_record` VALUES ('54', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:27');
INSERT INTO `looker_operation_record` VALUES ('55', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:29');
INSERT INTO `looker_operation_record` VALUES ('56', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:30');
INSERT INTO `looker_operation_record` VALUES ('57', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:30');
INSERT INTO `looker_operation_record` VALUES ('58', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:31');
INSERT INTO `looker_operation_record` VALUES ('59', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:32');
INSERT INTO `looker_operation_record` VALUES ('60', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:32');
INSERT INTO `looker_operation_record` VALUES ('61', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:34');
INSERT INTO `looker_operation_record` VALUES ('62', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:35');
INSERT INTO `looker_operation_record` VALUES ('63', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:35');
INSERT INTO `looker_operation_record` VALUES ('64', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:36');
INSERT INTO `looker_operation_record` VALUES ('65', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:37');
INSERT INTO `looker_operation_record` VALUES ('66', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:37');
INSERT INTO `looker_operation_record` VALUES ('67', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:39');
INSERT INTO `looker_operation_record` VALUES ('68', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:40');
INSERT INTO `looker_operation_record` VALUES ('69', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:40');
INSERT INTO `looker_operation_record` VALUES ('70', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:41');
INSERT INTO `looker_operation_record` VALUES ('71', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:42');
INSERT INTO `looker_operation_record` VALUES ('72', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:42');
INSERT INTO `looker_operation_record` VALUES ('73', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:44');
INSERT INTO `looker_operation_record` VALUES ('74', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:45');
INSERT INTO `looker_operation_record` VALUES ('75', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:45');
INSERT INTO `looker_operation_record` VALUES ('76', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:46');
INSERT INTO `looker_operation_record` VALUES ('77', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/process.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:48');
INSERT INTO `looker_operation_record` VALUES ('78', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/system.cpu.usage', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:48');
INSERT INTO `looker_operation_record` VALUES ('79', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:48');
INSERT INTO `looker_operation_record` VALUES ('80', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:51');
INSERT INTO `looker_operation_record` VALUES ('81', 'a46d8db507a6', 'admin-client', 'ucar', 'ucarinc-framework-paret_6.14', '10.99.32.136', 'http://10.99.32.136:8091/client1', '/instances/a46d8db507a6/actuator/metrics/jvm.gc.pause', '{}', 'xianwei.liu@ucarinc.com', '刘县委', 'admin', '2020-05-07 17:28:53');

-- ----------------------------
-- Table structure for `looker_project_info`
-- ----------------------------
DROP TABLE IF EXISTS `looker_project_info`;
CREATE TABLE `looker_project_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `instance_id` varchar(30) DEFAULT NULL COMMENT '实例id',
  `project_name` varchar(100) DEFAULT NULL COMMENT '项目名称',
  `business_line` varchar(20) DEFAULT NULL COMMENT '业务线',
  `ip` varchar(30) DEFAULT NULL COMMENT '服务器的ip地址',
  `status` varchar(15) DEFAULT NULL COMMENT '项目状态',
  `service_url` varchar(150) DEFAULT NULL COMMENT '客户端的服务url',
  `health_url` varchar(150) DEFAULT NULL COMMENT '客户端的服务healthurl',
  `management_url` varchar(150) DEFAULT NULL COMMENT '客户端的服务managementurl',
  `framework_version` varchar(50) DEFAULT NULL COMMENT '使用的framework 的版本号',
  `version` varchar(100) DEFAULT NULL COMMENT '版本号',
  `tags` varchar(150) DEFAULT NULL COMMENT 'tags',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_instance_index` (`instance_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8 COMMENT='项目信息表';

-- ----------------------------
-- Records of looker_project_info
-- ----------------------------
INSERT INTO `looker_project_info` VALUES ('18', 'a46d8db507a6', 'admin-client', 'ucar', '10.99.32.136', 'UP', 'http://10.99.32.136:8091/client1', 'http://10.99.32.136:8071/management/actuator/health', 'http://10.99.32.136:8071/management/actuator', 'ucarinc-framework-strict-parent_6.17', '1.0.2', '{\"values\":{\"busiLine\":\"ucar\",\"pomParent\":\"ucarinc-framework-parent_6.8\"}}', '2020-04-14 11:00:39', '2020-05-09 16:13:40');
