# 创建数据库Library
CREATE DATABASE IF NOT EXISTS Library;

# 使用数据库library
USE library;

# 创建学生信息表
CREATE TABLE StudentInfo(
borrow_number int primary key,	   #借书证号
student_name char(3),			   #姓名
student_id char(3),				   #学号
class_name char(20),			   #班级名称
borrow_privileges char(2),		   #借阅权限
student_contact varchar(15)		   #联系方式
);

# 创建图书信息表
CREATE TABLE BookInfo(
book_number char(20) primary key,	#图书编号
book_author char(20),				#作者
book_state char(2),					#图书状态
book_price decimal(8,1),			#图书价格
book_cate char(5)					#图书类别编号
);

# 创建图书类别表
CREATE TABLE BookCate(
book_cate char(5)	primary key,	#图书类别编号
category_name char(20),				#类别名称
book_located char(3)				#所在馆室
);

# 创建业务信息表
CREATE TABLE BusinessInfo(
business_number int primary key,	#业务编号
business_cate char(2),			 	#业务类型编号
borrow_date date,					#借书日期
return_date date,			 		#还书日期
loss_date date,		 				#挂失日期
borrow_number int,				 	#借书证号
book_number char(20)				#图书编号
);

# 创建业务类型表
CREATE TABLE BusinessCate(
business_cate char(2) primary key,	 #业务类型编号
business_type char(2)			     #业务类型名
);


# 插入信息
INSERT INTO studentinfo(borrow_number, student_name, student_id, class_name, borrow_privileges, student_contact)
VALUES
('20220001','刘志强','001','22级计算机一班','正常',18877654534),
('20220002','张霞','002','22级护理三班','正常',13788765531),
('20220003','李亚','003','21级园林二班','异常',13999807749),
('20220004','王小明','004','20级会计一班','正常',13212214433);
    
INSERT INTO bookinfo(book_number, book_author, book_state, book_price, book_cate)
VALUES
('Bk0000001','张友良','在库',44.5,'BC001'),
('Bk0000002','李志','在库',25,'BC004'),
('Bk0000003','刘丽','借出',35.5,'BC002'),
('Bk0000004','王刚','在库',20.5,'BC003');

INSERT INTO bookcate(book_cate, category_name, book_located)
VALUES
('BC001', '计算机类', 'A01'),
('BC002', '财经类', 'B01'),
('BC003', '历史类', 'C01'),
('BC004', '文学类', 'D01');

INSERT INTO businessinfo(business_number, business_cate, borrow_date, return_date, loss_date, borrow_number, book_number)
VALUES
(1, '01','2022-01-01', NULL, NULL, '20220001', 'BK00000022'),
(20,'02', NULL, '2022-02-02', NULL, '20220002', 'BK00000138'),
(877,'03', NULL, '2022-03-04', NULL, '20220003', 'BK00000322'),
(998,'01', NULL, NULL, '2022-04-06', '20220004', 'BK00000661');

INSERT INTO businesscate(business_cate, business_type)
VALUES
('01','借书'),
('02','还书'),
('03','挂失');

# 创建BorrowBooks表来记录借书信息，并且每次借书都会向该表中插入一条新记录
CREATE TABLE BorrowBooks AS
SELECT business_number AS borrow_id, -- 给业务编号起个别名borrow_id，以便更清楚地表示这是借书ID
       business_cate,
       borrow_date,
       NULL AS return_date, -- 如果在借书时还没有还书日期，则设置为NULL
       NULL AS loss_date,   -- 如果在借书时还没有挂失日期，则设置为NULL
       borrow_number,
       book_number
FROM BusinessInfo
WHERE business_cate = '01';

# 创建ReturnBooks表来记录还书信息，并且每次还书都会向该表中插入一条新记录
CREATE TABLE ReturnBooks AS
SELECT business_number AS return_id,  -- 给业务编号起个别名return_id，表示还书ID
       business_cate,
       NULL AS borrow_date,           -- 还书记录通常不包含借书日期，因此设置为NULL
       return_date,
       NULL AS loss_date,             -- 还书时通常不处理挂失日期，因此设置为NULL
       borrow_number,                 
       book_number
FROM BusinessInfo
WHERE business_cate = '02';


# 3.（1）查询“刘志强”同学借了哪本书
SELECT book_number
FROM borrowbooks
JOIN studentinfo
ON studentinfo.borrow_number = borrowbooks.borrow_number
WHERE student_name = '刘志强';

# 3.（2）查询图书编号“Bk0000001”的书的业务类型名（借书、还书还是挂失，在库）
# 查询图书的当前状态
SELECT bi.book_state AS current_state
FROM BookInfo bi
WHERE bi.book_number = 'Bk0000001';
# 查询图书的最近业务操作类型
SELECT bc.business_type
FROM BusinessInfo bi_info
JOIN BusinessCate bc ON bi_info.business_cate = bc.business_cate
WHERE bi_info.book_number = 'Bk0000001'
ORDER BY COALESCE(bi_info.borrow_date, bi_info.return_date, bi_info.loss_date) DESC 
LIMIT 1; # 只获取最近的一条记录

# 关闭workbench预设的更新模式
set SQL_SAFE_UPDATES = 0;

# 4.（1）创建用于管理图书的视图。用于查询、插入、更新、删除图书信息。
CREATE VIEW view_books AS
SELECT book_number, book_author, book_state, book_price, book_cate
FROM bookinfo;

# 4.（2）用于查询学生已办的业务的视图。用于查询已办业务，可以根据学生的借书证号或图书编号等查询所办业务（但通常只会根据借书证进行查询）
CREATE VIEW StudentBusiness AS
SELECT
    s.borrow_number AS 借书证号, 
    s.student_name AS 学生姓名,
    b.book_number AS 图书编号,
    bc.business_type AS 业务类型,
    bi.borrow_date AS 借书日期,
    bi.return_date AS 还书日期,
    bi.loss_date AS 挂失日期
FROM
    StudentInfo s
LEFT JOIN
    BusinessInfo bi ON s.borrow_number = bi.borrow_number 
LEFT JOIN
    BookInfo b ON bi.book_number = b.book_number 
LEFT JOIN
    BusinessCate bc ON bi.business_cate = bc.business_cate 
WHERE
    bi.borrow_number IS NOT NULL;


# 创建用于学生管理的视图。用于查询、插入、更新、删除学生信息。
CREATE VIEW view_students AS
SELECT borrow_number, student_name, student_id, class_name, borrow_privileges, student_contact
FROM studentinfo;

# 创建图书类别的管理的视图。用于查询、插入、更新、删除图书类别。
CREATE VIEW view_cate AS
SELECT book_cate, category_name, book_located
FROM bookcate;


# 5.（1）创建查询图书信息存储过程。用于通过参数查询图书信息
DELIMITER //
CREATE PROCEDURE QueryBookInfo(
    IN book_number VARCHAR(255),
    IN book_author VARCHAR(255)
)
BEGIN
    #构建查询语句的起始部分
    SET @sql = 'SELECT * FROM view_books WHERE 1=1';
    
    #根据参数动态添加条件
    IF book_number IS NOT NULL THEN
		SET @sql = CONCAT(@sql, ' AND book_number = ''', book_number, '''');
    END IF;
    
    IF book_author IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND book_author = ''', book_author, '''');
    END IF;

    #准备和执行动态 SQL
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

# 创建用于学生信息存储过程。用于查询、插入、更新、删除学生信息。
DELIMITER //
CREATE PROCEDURE QueryStudentInfo(
	IN borrow_number VARCHAR(255),
    IN student_name VARCHAR(255),
    IN class_name VARCHAR(255)
)
BEGIN
    -- 构建查询语句
    SET @sql = 'SELECT * FROM view_students WHERE 1=1';
    
    -- 根据参数动态添加条件
	IF borrow_number IS NOT NULL AND borrow_number <> '' THEN
        SET @sql = CONCAT(@sql, ' AND borrow_number LIKE ''%', borrow_number, '%''');
    END IF;
    
    IF student_name IS NOT NULL AND student_name <> '' THEN
        SET @sql = CONCAT(@sql, ' AND student_name LIKE ''%', student_name, '%''');
    END IF;
    
    IF class_name IS NOT NULL AND class_name <> '' THEN
        SET @sql = CONCAT(@sql, ' AND class_name LIKE ''%', class_name, '%''');
    END IF;

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;    
END //
DELIMITER ;


DELIMITER //
# 6.（1）借书业务办理时，相应的书籍的图书状态自动改为“借出”
CREATE TRIGGER TRG_AFTER_BORROW
AFTER INSERT ON BorrowBooks
FOR EACH ROW
BEGIN
    UPDATE BookInfo
    SET book_state = '借出'
    WHERE book_number = NEW.book_number; 
END //


DELIMITER //
# 还书业务办理时，相应的书籍的图书状态自动改为“在库”
CREATE TRIGGER TRG_AFTER_RETURN
AFTER INSERT ON ReturnBooks
FOR EACH ROW
BEGIN
    UPDATE BookInfo
    SET book_state = '在库'
    WHERE book_number = NEW.book_number;
END //
DELIMITER ;

