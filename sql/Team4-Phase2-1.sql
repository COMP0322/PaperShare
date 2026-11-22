CREATE TABLE USERS (
    user_id         NUMBER          NOT NULL,
    name            VARCHAR2(100)   NOT NULL,
    email           VARCHAR2(100)   NOT NULL,
    affiliation     VARCHAR2(100)   NOT NULL,
    PRIMARY KEY (user_id)
);

CREATE TABLE STUDY_GROUP (
    group_id        NUMBER          NOT NULL,
    group_name      VARCHAR2(100)   NOT NULL,
    created_at      TIMESTAMP       NOT NULL,
    description     VARCHAR2(1000)  NOT NULL,
    PRIMARY KEY (group_id)
);

CREATE TABLE PAPER (
    paper_id        NUMBER          NOT NULL,
    title           VARCHAR2(300)   NOT NULL,
    authors         VARCHAR2(300)   NOT NULL,
    year            NUMBER(4)       NOT NULL,
    DOI             VARCHAR2(100)   NOT NULL,
    url             VARCHAR2(100)   NOT NULL,
    abstract        VARCHAR2(4000)  NOT NULL,
    PRIMARY KEY (paper_id),
    CHECK (year >= 1 AND year <= 9999)
);

CREATE TABLE TAG (
    tag_id          NUMBER          NOT NULL,
    tag_name        VARCHAR2(100)   NOT NULL,
    PRIMARY KEY (tag_id)
);

CREATE TABLE GROUP_PAPER (
    group_paper_id  NUMBER          NOT NULL,
    group_id        NUMBER          NOT NULL,
    paper_id        NUMBER          NOT NULL,
    status          VARCHAR2(30)    NOT NULL,
    added_date      DATE            NOT NULL,
    started_date    DATE,
    completed_date  DATE,
    notes           VARCHAR2(4000)  NOT NULL,
    PRIMARY KEY (group_paper_id),
    UNIQUE (group_id, paper_id),
    FOREIGN KEY (group_id)
        REFERENCES STUDY_GROUP(group_id)
        ON DELETE CASCADE,
    FOREIGN KEY (paper_id)
        REFERENCES PAPER(paper_id)
        ON DELETE CASCADE,
    CHECK (completed_date >= started_date)
);

CREATE TABLE MEMBER_OF (
    user_id         NUMBER          NOT NULL,
    group_id        NUMBER          NOT NULL,
    role            VARCHAR2(30)    NOT NULL,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id)
        REFERENCES USERS(user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (group_id)
        REFERENCES STUDY_GROUP(group_id)
        ON DELETE CASCADE
);

CREATE TABLE PAPER_TAG (
    paper_id        NUMBER          NOT NULL,
    tag_id          NUMBER          NOT NULL,
    PRIMARY KEY (paper_id, tag_id),
    FOREIGN KEY (paper_id)
        REFERENCES PAPER(paper_id)
        ON DELETE CASCADE,
    FOREIGN KEY (tag_id)
        REFERENCES TAG(tag_id)
        ON DELETE CASCADE
);

CREATE TABLE HIGHLIGHT (
    group_paper_id  NUMBER          NOT NULL,
    highlight_no    NUMBER          NOT NULL,
    user_id         NUMBER          NOT NULL,
    page_no         NUMBER          NOT NULL,
    start_position  NUMBER          NOT NULL,
    end_position    NUMBER          NOT NULL,
    color           VARCHAR2(30)    NOT NULL,
    selected_text   VARCHAR2(1000)  NOT NULL,
    created_at      TIMESTAMP       NOT NULL,
    PRIMARY KEY (group_paper_id, highlight_no),
    FOREIGN KEY (group_paper_id)
        REFERENCES GROUP_PAPER(group_paper_id)
        ON DELETE CASCADE,
    FOREIGN KEY (user_id)
        REFERENCES USERS(user_id),
    CHECK (end_position > start_position)
);

CREATE TABLE PAPER_COMMENT (
    group_paper_id    NUMBER            NOT NULL,
    comment_no        NUMBER            NOT NULL,
    user_id           NUMBER            NOT NULL,
    highlight_no      NUMBER,
    parent_comment_no NUMBER,
    content           VARCHAR2(1000)    NOT NULL,
    created_at        TIMESTAMP         NOT NULL,
    updated_at        TIMESTAMP,
    PRIMARY KEY (group_paper_id, comment_no),
    FOREIGN KEY (group_paper_id)
        REFERENCES GROUP_PAPER(group_paper_id)
        ON DELETE CASCADE,
    FOREIGN KEY (user_id)
        REFERENCES USERS(user_id),
    FOREIGN KEY (group_paper_id, highlight_no)
        REFERENCES HIGHLIGHT(group_paper_id, highlight_no),
    FOREIGN KEY (group_paper_id, parent_comment_no)
        REFERENCES PAPER_COMMENT(group_paper_id, comment_no),
    CHECK (updated_at >= created_at)
);

CREATE SEQUENCE study_group_seq
    NOCACHE;

CREATE SEQUENCE paper_seq
    NOCACHE;

CREATE SEQUENCE group_paper_seq
    NOCACHE;
