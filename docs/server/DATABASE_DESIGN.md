# Database Design

Database:
PostgreSQL


## Tables


categories

- id
- name_bg
- name_en
- sort_order


products

- id
- category_id
- name_bg
- name_en
- description
- price_eur
- price_bgn
- image
- active


events

- id
- title_bg
- title_en
- description
- date
- image
- video


gallery

- id
- event_id
- filename


users

- id
- username
- password_hash
- role
