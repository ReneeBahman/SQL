# 💾 SQL Portfolio by Renee Bahman

Welcome! This repository showcases my work in SQL — including ETL pipelines, reporting queries, and learning snippets. The structure reflects both hands-on project experience and continuous learning through platforms like DataCamp and professional challenges.

---

## 📁 Repository Structure

| Folder               | Description                                                                 |
|----------------------|-----------------------------------------------------------------------------|
| `etl/`               | Full end-to-end ETL pipeline with retry logic, transactional control, and reporting layer (Sybase SQL compatible). Includes mock data for standalone execution. |
| `reporting/`         | SQL queries and views used to generate KPIs, customer segmentation, and summaries. |
| `datacamp_snippets/` | Solutions and challenges from SQL courses on DataCamp and other learning platforms. |
| `snippets/`          | Reusable SQL patterns, such as string manipulation, conditional logic, and date handling. |

---

## 🧩 Highlight: ETL Customer Loan Summary

Inside `etl/` you'll find:
- A complete OLTP model with mock data: [`data_model_for_etl.txt`](./etl/data_model_for_etl.txt)
- A stored procedure: `etl_customer_summary` that loads and transforms data into a reporting table
- Retry loop and transactional rollback logic for fault tolerance
- A view: `vw_customer_loan_summary` ready for BI tools like Tableau or Power BI

> Designed as a hands-on demonstration for real-world ETL support roles (like Luminor interview case studies).

---

## 📈 Goals

This repo is designed to:
- Demonstrate real-life ETL logic in a bank-like setting
- Share practical SQL patterns and reusables
- Show clear documentation, consistent structure, and working examples

---

## 📬 Contact

- **LinkedIn**: [https://www.linkedin.com/in/renee-bahman-1b04251a7/](https://www.linkedin.com/in/renee-bahman-1b04251a7/)
- **Email**: renee.bahman@gmail.com

---

Thank you for visiting! ⭐  
Feel free to fork, explore, or connect — I’m always up for data challenges and collaborations.
