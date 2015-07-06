-- MySQL Script generated by MySQL Workbench
-- Ср. 03 июня 2015 12:06:21
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema forumdb
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `forumdb` ;

-- -----------------------------------------------------
-- Schema forumdb
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `forumdb` DEFAULT CHARACTER SET utf8 ;
USE `forumdb` ;

-- -----------------------------------------------------
-- Table `forumdb`.`Users`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forumdb`.`Users` ;

CREATE TABLE IF NOT EXISTS `forumdb`.`Users` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(50) NOT NULL,
  `about` TEXT NULL,
  `isAnonymous` TINYINT(1) NULL DEFAULT 0,
  `name` VARCHAR(100) NULL,
  `username` VARCHAR(50) NULL,
  PRIMARY KEY (`id`, `email`),
  UNIQUE INDEX `email` (`email`),
  INDEX `name` (`name`),
  UNIQUE INDEX `id` (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forumdb`.`Forums`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forumdb`.`Forums` ;

CREATE TABLE IF NOT EXISTS `forumdb`.`Forums` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `short_name` VARCHAR(50) NOT NULL,
  `user_id` INT NOT NULL,
  PRIMARY KEY (`id`, `short_name`),
  UNIQUE INDEX `short_name` (`short_name`),
  UNIQUE INDEX `id` (`id`),
  INDEX `user_id` (`user_id`),
  CONSTRAINT `fk_forum_user`
    FOREIGN KEY (`user_id`)
    REFERENCES `Users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forumdb`.`Threads`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forumdb`.`Threads` ;

CREATE TABLE IF NOT EXISTS `forumdb`.`Threads` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `count` INT NOT NULL DEFAULT 0,
  `isClosed` TINYINT(1) NOT NULL DEFAULT 0,
  `isDeleted` TINYINT(1) NOT NULL,
  `slug` VARCHAR(50) NOT NULL,
  `title` VARCHAR(100) NOT NULL,
  `forum_id` INT NOT NULL,
  `user_id` INT NOT NULL,
  `date` DATETIME NOT NULL,
  `dislikes` INT NOT NULL DEFAULT 0,
  `likes` INT NOT NULL DEFAULT 0,
  `message` TEXT NOT NULL,
  `points` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `id` (`id`),
  INDEX `forum_thread` (`id`, `forum_id`),
  INDEX `Threads_isDeleted` (`isDeleted`),
  INDEX `forum_id` (`forum_id`),
  INDEX `user_id` (`user_id`),
  INDEX `Threads_date_asc` (`date` ASC),
  INDEX `Threads_date_desc` (`date` DESC),
  CONSTRAINT `fk_thread_forum`
    FOREIGN KEY (`forum_id`)
    REFERENCES `forumdb`.`Forums` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_thread_user`
    FOREIGN KEY (`user_id`)
    REFERENCES `forumdb`.`Users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forumdb`.`Posts`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forumdb`.`Posts` ;

CREATE TABLE IF NOT EXISTS `forumdb`.`Posts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `date` DATETIME NOT NULL,
  `message` TEXT NOT NULL,
  `parent_id` INT DEFAULT NULL,
  `user_id` INT NOT NULL,
  `thread_id` INT NOT NULL,
  `dislikes` INT NOT NULL DEFAULT 0,
  `likes` INT NOT NULL DEFAULT 0,
  `points` INT NOT NULL DEFAULT 0,
  `isApproved` TINYINT(1) NOT NULL,
  `isDeleted` TINYINT(1) NOT NULL,
  `isEdited` TINYINT(1) NOT NULL,
  `isHighlighted` TINYINT(1) NOT NULL,
  `isSpam` TINYINT(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `id` (`id`),
  INDEX `Posts_date_asc` (`date` ASC),
  INDEX `Posts_date_desc` (`date` DESC),
  INDEX `parent_id` (`parent_id`),
  INDEX `user_id` (`user_id`),
  INDEX `thread_id` (`thread_id`),
  INDEX `Posts_isDeleted` (`isDeleted`),
  CONSTRAINT `fk_post_post`
    FOREIGN KEY (`parent_id`)
    REFERENCES `forumdb`.`Posts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_post_user`
    FOREIGN KEY (`user_id`)
    REFERENCES `forumdb`.`Users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_post_thread`
    FOREIGN KEY (`thread_id`)
    REFERENCES `forumdb`.`Threads` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forumdb`.`Followers`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forumdb`.`Followers` ;

CREATE TABLE IF NOT EXISTS `forumdb`.`Followers` (
  `follower_id` INT NOT NULL,
  `followee_id` INT NOT NULL,
  PRIMARY KEY (`follower_id`, `followee_id`),
  INDEX `followee_id` (`followee_id` ASC),
  INDEX `follower_id` (`follower_id` ASC),
  CONSTRAINT `fk_follower_id`
    FOREIGN KEY (`follower_id`)
    REFERENCES `forumdb`.`Users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_followee_id`
    FOREIGN KEY (`followee_id`)
    REFERENCES `forumdb`.`Users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forumdb`.`Subscriptions`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forumdb`.`Subscriptions` ;

CREATE TABLE IF NOT EXISTS `forumdb`.`Subscriptions` (
  `user_id` INT NOT NULL,
  `thread_id` INT NOT NULL,
  PRIMARY KEY (`user_id`, `thread_id`),
  INDEX `thread_id` (`thread_id` ASC),
  INDEX `user_id` (`user_id` ASC),
  CONSTRAINT `fk_user_id`
    FOREIGN KEY (`user_id`)
    REFERENCES `forumdb`.`Users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_thread_id`
    FOREIGN KEY (`thread_id`)
    REFERENCES `forumdb`.`Threads` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;