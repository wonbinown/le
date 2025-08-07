진짜 진짜 수정사항
0808자로 
db는 아래와 같습니다..카톡방에 올린거랑 다름!!

DROP table users cascade CONSTRAINTS;
DROP SEQUENCE seq_users;
-- 1-1) 시퀀스: users.user_id 자동 증가
CREATE SEQUENCE seq_users
  START WITH 1        -- 시작값 1
  INCREMENT BY 1      -- 1씩 증가
  NOCACHE             -- 캐시 사용 안 함 (운영 시 CACHE 권장)
  NOCYCLE;            -- 순환 없이  계속 증가

-- 1-2) 테이블 정의
CREATE TABLE users (
  user_id   NUMBER         NOT NULL,                       -- PK: 내부 식별자
  login_id  VARCHAR2(30)   NOT NULL,                       -- 로그인용 아이디(중복 불가)
  password  VARCHAR2(100)  NOT NULL,                       -- 비밀번호 해시
  name      VARCHAR2(20)   NOT NULL,                       -- 실명 또는 표시명
  email     VARCHAR2(50)   NOT NULL,                       -- 이메일(중복 불가)
  hp        VARCHAR2(20),                                  -- 휴대폰 번호(선택)
  role      VARCHAR2(20)   DEFAULT 'ROLE_CUSTOMER' NOT NULL, -- 권한

  CONSTRAINT pk_users         PRIMARY KEY (user_id),
  CONSTRAINT uk_users_login   UNIQUE (login_id),
  CONSTRAINT uk_users_email   UNIQUE (email),
  CONSTRAINT chk_users_role   CHECK (role IN ('ROLE_CUSTOMER','ROLE_ADMIN'))
);


-- 1-3) 트리거: INSERT 시 user_id에 시퀀스 값 할당
CREATE OR REPLACE TRIGGER trg_users_bi
  BEFORE INSERT ON users
  FOR EACH ROW
BEGIN
  -- 수동 할당이 없으면(=NULL) 시퀀스에서 NEXTVAL을 받아옴
  IF :NEW.user_id IS NULL THEN
    SELECT seq_users.NEXTVAL
      INTO :NEW.user_id
      FROM dual;
  END IF;
END;
/
DROP TABLE books CASCADE CONSTRAINTS;
DROP SEQUENCE seq_books;
-- ====================================
-- 2) 도서 테이블: books
--   - 판매할 도서 정보 저장
--   - book_id: 내부 식별용 숫자 키
--   - title, author, description, price, stock, cover_image
-- ====================================
-- 2-1) 시퀀스: books.book_id 자동 증가
CREATE SEQUENCE seq_books
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- 2-2) 테이블 정의
CREATE TABLE books (
  book_id     NUMBER             NOT NULL,              -- PK
  title       VARCHAR2(100) NOT NULL,              -- 도서 제목
  author      VARCHAR2(50) NOT NULL,              -- 저자명
  description CLOB,                                      -- 상세 설명(길이 무제한)
  price       NUMBER(10)       NOT NULL,              -- 판매가(0 이상)
  stock       NUMBER(10)         DEFAULT 0 NOT NULL,    -- 재고 수량(음수 불가)
  cover_image VARCHAR2(300),                       -- 표지 이미지 URL
  
  CONSTRAINT pk_books          PRIMARY KEY (book_id),
  CONSTRAINT chk_books_price  CHECK (price >= 0),        -- 가격 검증
  CONSTRAINT chk_books_stock  CHECK (stock >= 0)         -- 재고 검증
);

-- 2-3) 트리거: INSERT 시 book_id에 시퀀스 값 할당
CREATE OR REPLACE TRIGGER trg_books_bi
  BEFORE INSERT ON books
  FOR EACH ROW
BEGIN
  IF :NEW.book_id IS NULL THEN
    SELECT seq_books.NEXTVAL
      INTO :NEW.book_id
      FROM dual;
  END IF;
END;
/
--기존 시퀀스 확인
SELECT sequence_name FROM user_sequences WHERE sequence_name = 'SEQ_BOOKS';
--특정 테이블의 제약조건 전체보기
SELECT constraint_name,
       constraint_type,
       table_name,
       search_condition,
       r_constraint_name
FROM user_constraints
WHERE table_name = 'BOOKS';
SELECT constraint_name,
       column_name,
       position
FROM user_cons_columns
WHERE table_name = 'BOOKS';
DROP table carts cascade CONSTRAINTS;
DROP SEQUENCE seq_carts;
-- 3-1) 시퀀스: carts.cart_id 자동 증가
CREATE SEQUENCE seq_carts
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- 3-2) 테이블 정의
CREATE TABLE carts (
  cart_id NUMBER NOT NULL,       -- PK: 장바구니 식별자
  user_id NUMBER NOT NULL,       -- FK: users.user_id 참조
  
  CONSTRAINT pk_carts        PRIMARY KEY (cart_id),
  CONSTRAINT fk_carts_user   FOREIGN KEY (user_id)
    REFERENCES users(user_id)   -- 사용자와 1:N 관계
);

-- 3-3) 트리거: INSERT 시 cart_id에 시퀀스 값 할당
CREATE OR REPLACE TRIGGER trg_carts_bi
  BEFORE INSERT ON carts
  FOR EACH ROW
BEGIN
  IF :NEW.cart_id IS NULL THEN
    SELECT seq_carts.NEXTVAL
      INTO :NEW.cart_id
      FROM dual;
  END IF;
END;
/
DROP table cart_items cascade CONSTRAINTS;
DROP SEQUENCE seq_cart_items;
-- 4-1) 시퀀스: cart_items.cart_item_id 자동 증가
CREATE SEQUENCE seq_cart_items
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- 4-2) 테이블 정의
CREATE TABLE cart_items (
  cart_item_id NUMBER        NOT NULL,                -- PK
  cart_id      NUMBER        NOT NULL,                -- FK: carts.cart_id 참조
  book_id      NUMBER        NOT NULL,                -- FK: books.book_id 참조
  quantity     NUMBER(8)     DEFAULT 1 NOT NULL,      -- 수량(1 이상)
  
  CONSTRAINT pk_cart_items       PRIMARY KEY (cart_item_id),
  CONSTRAINT fk_cart_items_cart  FOREIGN KEY (cart_id)
    REFERENCES carts(cart_id)
    ON DELETE CASCADE,           -- carts 삭제 시 자동으로 해당 항목 삭제
  CONSTRAINT fk_cart_items_book  FOREIGN KEY (book_id)
    REFERENCES books(book_id),
  CONSTRAINT chk_cart_items_qty  CHECK (quantity >= 1) -- 수량 검증
);

-- 4-3) 트리거: INSERT 시 cart_item_id에 시퀀스 값 할당
CREATE OR REPLACE TRIGGER trg_cart_items_bi
  BEFORE INSERT ON cart_items
  FOR EACH ROW
BEGIN
  IF :NEW.cart_item_id IS NULL THEN
    SELECT seq_cart_items.NEXTVAL
      INTO :NEW.cart_item_id
      FROM dual;
  END IF;
END;
/
DROP table orders cascade CONSTRAINTS;
DROP SEQUENCE seq_orders;
-- ====================================
-- 5) 주문 헤더 테이블: orders
--   - 주문 정보(누가, 언제, 상태, 총금액) 저장
-- ====================================

-- 5-1) 시퀀스: orders.order_id 자동 증가
-- 5) 주문 헤더 테이블: orders (배송지 컬럼 추가 버전)
--   - 주문 정보(누가, 언제, 상태, 총금액) 저장
--   - address: 배송지 주소
--   - postcode: 배송지 우편번호

-- 5-1) 시퀀스: orders.order_id 자동 증가
CREATE SEQUENCE seq_orders
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- 5-2) 테이블 정의 (address, postcode 컬럼 추가)
CREATE TABLE orders (
  order_id       NUMBER            NOT NULL,                -- PK
  user_id        NUMBER            NOT NULL,                -- FK: users.user_id 참조
  status         VARCHAR2(20)      DEFAULT 'PENDING' NOT NULL, -- 주문 상태
  total_amount   NUMBER(12)        NOT NULL,                -- 주문 총액(0 이상)
  address        VARCHAR2(200 CHAR) NOT NULL,               -- 배송지 주소
  postcode       VARCHAR2(10 CHAR)  NOT NULL,               -- 배송지 우편번호

  CONSTRAINT pk_orders           PRIMARY KEY (order_id),
  CONSTRAINT fk_orders_user      FOREIGN KEY (user_id)
    REFERENCES users(user_id),
  CONSTRAINT chk_orders_status   CHECK (status IN ('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED')),
  CONSTRAINT chk_orders_amount   CHECK (total_amount >= 0)
);

-- 5-3) 트리거: INSERT 시 order_id에 시퀀스 값 할당
CREATE OR REPLACE TRIGGER trg_orders_bi
  BEFORE INSERT ON orders
  FOR EACH ROW
BEGIN
  IF :NEW.order_id IS NULL THEN
    SELECT seq_orders.NEXTVAL
      INTO :NEW.order_id
      FROM dual;
  END IF;
END;
/
DROP table order_items cascade CONSTRAINTS;
DROP SEQUENCE seq_order_items;
-- ====================================
-- 6) 주문 항목 테이블: order_items
--   - 한 주문(order_id)에 포함된 여러 도서(book_id)를 관리
--   - quantity, unit_price: 수량 및 주문 시점 단가 저장
-- ====================================

-- 6-1) 시퀀스: order_items.order_item_id 자동 증가
CREATE SEQUENCE seq_order_items
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- 6-2) 테이블 정의
CREATE TABLE order_items (
  order_item_id NUMBER       NOT NULL,                -- PK
  order_id      NUMBER       NOT NULL,                -- FK: orders.order_id 참조
  book_id       NUMBER       NOT NULL,                -- FK: books.book_id 참조
  quantity      NUMBER(8)    DEFAULT 1 NOT NULL,      -- 수량(1 이상)
  unit_price    NUMBER(12) NOT NULL,                -- 주문 당시 단가
  
  CONSTRAINT pk_order_items       PRIMARY KEY (order_item_id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
    ON DELETE CASCADE,             -- orders 삭제 시 자동으로 해당 항목 삭제
  CONSTRAINT fk_order_items_book  FOREIGN KEY (book_id)
    REFERENCES books(book_id),
  CONSTRAINT chk_oitems_quantity  CHECK (quantity >= 1),
  CONSTRAINT chk_oitems_unitprice CHECK (unit_price >= 0)
);

-- 6-3) 트리거: INSERT 시 order_item_id에 시퀀스 값 할당
CREATE OR REPLACE TRIGGER trg_order_items_bi
  BEFORE INSERT ON order_items
  FOR EACH ROW
BEGIN
  IF :NEW.order_item_id IS NULL THEN
    SELECT seq_order_items.NEXTVAL
      INTO :NEW.order_item_id
      FROM dual;
  END IF;
END;
/
commit;
INSERT INTO books (title, author, description, price, stock) VALUES ('혼모노', '김민섭', '타인의 시선과 편견을 넘어 자신만의 길을 찾는 에세이.', 15800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불편한 편의점', '김호연', '서울역에 나타난 한 남자와 편의점 사람들의 따뜻한 이야기.', 14000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('역행자', '자청', '인생을 바꾸는 자기혁명과 실천 전략을 담은 자기계발서.', 17500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('세이노의 가르침', '세이노', '삶과 돈에 대한 현실적 조언을 담은 인생 지침서.', 6800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('트렌드 코리아 2025', '김난도 외', '2025년 대한민국을 관통할 10대 소비트렌드 전망.', 19800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불변의 법칙', '모건 하우절', '부와 성공을 지키는 심리와 행동의 법칙을 설명.', 18000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('아주 희미한 빛으로도', '정세랑', '일상과 환상이 교차하는 따뜻한 단편 소설집.', 15500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('하얼빈', '김훈', '안중근의 삶과 역사적 순간을 소설로 재해석.', 14800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('도둑맞은 집중력', '요한 하리', '현대인의 집중력 저하 원인과 해결책을 탐구.', 18800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('이기적 유전자', '리처드 도킨스', '진화론의 관점에서 본 인간과 생명의 본질.', 18000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('미드나잇 라이브러리', '매트 헤이그', '인생의 갈림길에서 선택의 의미를 돌아보는 소설.', 15500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('파친코', '이민진', '재일 조선인 가족의 삶을 그린 대하소설.', 16800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불편한 편의점 2', '김호연', '편의점 사람들의 새로운 이야기와 성장.', 14500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('달러구트 꿈 백화점', '이미예', '꿈을 사고파는 신비한 백화점의 이야기.', 13800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('달러구트 꿈 백화점 2', '이미예', '꿈 백화점의 새로운 에피소드와 손님들.', 13800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불안', '알랭 드 보통', '불안의 심리를 철학적으로 탐구하는 에세이.', 13800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('아몬드', '손원평', '감정을 느끼지 못하는 소년의 성장 소설.', 13000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('작별인사', '김영하', '인간과 인공지능의 경계에서 고민하는 소설.', 14500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('모순', '양귀자', '가족과 인생의 모순을 그린 한국 장편소설.', 14800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('죽고 싶지만 떡볶이는 먹고 싶어', '백세희', '우울과 일상에 대한 솔직한 에세이.', 13500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('지구 끝의 온실', '김초엽', '미래 지구의 생존과 희망을 그린 SF 소설.', 15300, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불편한 편의점 3', '김호연', '편의점 사람들의 또 다른 성장 이야기.', 15000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('공정하다는 착각', '마이클 샌델', '능력주의와 공정성에 대한 철학적 비판.', 17000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('역사의 쓸모', '최태성', '역사에서 배우는 삶의 지혜.', 16000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('기분을 관리하면 인생이 관리된다', '김다슬', '감정 관리의 중요성과 실천법을 제시.', 14800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불편한 편의점 4', '김호연', '편의점 시리즈의 마지막 이야기.', 15500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('나는 나로 살기로 했다', '김수현', '자존감 회복과 자기 사랑을 위한 에세이.', 13800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('아침에는 죽음을 생각하는 것이 좋다', '김영민', '삶과 죽음에 대한 철학적 에세이.', 14800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('완전한 행복', '정유정', '행복의 본질을 파헤치는 심리 스릴러.', 15800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('메리골드 마음 세탁소', '윤정은', '마음을 치유하는 세탁소의 따뜻한 이야기.', 14000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불변의 법칙 2', '모건 하우절', '부의 심리를 더 깊이 탐구하는 후속작.', 18500, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('나는 나로 살기로 했다 2', '김수현', '자기 자신을 사랑하는 법을 다시 묻다.', 14000, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('오늘 밤, 세계에서 이 사랑이 사라진다 해도', '이치조 미사키', '기억을 잃는 소녀와 소년의 사랑 이야기.', 14800, 10); INSERT INTO books (title, author, description, price, stock) VALUES ('불편한 편의점 5', '김호연', '편의점 사람들의 새로운 시작.', 15500, 10); commit;

----2-1 books 이미지 넣기

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788936439743.jpg' WHERE book_id = 3;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791161571188.jpg' WHERE book_id = 4;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788901272580.jpg' WHERE book_id = 5;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791168473690.jpg' WHERE book_id = 6;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788959897223.jpg' WHERE book_id = 7;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791198517425.jpg' WHERE book_id = 8;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788954695053.jpg' WHERE book_id = 9;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788954699914.jpg' WHERE book_id = 10;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791167742131.jpg' WHERE book_id = 11;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788932473901.jpg' WHERE book_id = 12;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791191056556.jpg' WHERE book_id = 13;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791168340510.jpg' WHERE book_id = 14;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791161571379.jpg' WHERE book_id = 15;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791165341909.jpg' WHERE book_id = 16;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791165343729.jpg' WHERE book_id = 17;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788956605593.jpg' WHERE book_id = 18;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791198363503.jpg' WHERE book_id = 19;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791191114225.jpg' WHERE book_id = 20;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9788998441012.jpg' WHERE book_id = 21;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791196394509.jpg' WHERE book_id = 22;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791191824001.jpg' WHERE book_id = 23;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791161571331.jpg' WHERE book_id = 24;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791164136452.jpg' WHERE book_id = 25;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791193401200.jpg' WHERE book_id = 26;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791196617127.jpg' WHERE book_id = 27;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/7070024000208.jpg' WHERE book_id = 28;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791197377150.jpg' WHERE book_id = 29;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791167741165.jpg' WHERE book_id = 30;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791167370280.jpg' WHERE book_id = 31;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791193937310.jpg' WHERE book_id = 32;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/S000213356402.jpg' WHERE book_id = 33;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791187119845.jpg' WHERE book_id = 34;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791191043297.jpg' WHERE book_id = 35;

UPDATE books SET cover_image = 'https://contents.kyobobook.co.kr/sih/fit-in/200x0/pdt/9791161572062.jpg' WHERE book_id = 36;
select * from books;
commit;
