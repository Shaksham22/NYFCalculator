# Front Closing App

A personal iOS app I built while working part-time at **New York Fries** to make my front-closing shifts faster, easier to track, and less error-prone.

At my store, closing was divided into **front closing** and **back closing**. I usually handled front closing, which involved counting cash, separating till money and bank deposit money, checking sales totals, filling closing sheets, and matching POS/DSR receipt values.

The manual calculation used to take around **35 minutes**. I built this app as a pet project for my own closing workflow, and it reduced the calculation time to **under 5 minutes**. It also helped track the cash breakdown clearly and reduced calculation errors significantly.

I could not publish it on the App Store because I did not have an Apple Developer account at the time, but my friends and peers at the store regularly used it from my phone during shifts.

---

## Manual Closing Forms

These are the paper sheets the app was designed around.

| Cash Float / Deposit Sheet                                                                        | Daily Sales Sheet                                                                                    |
| ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| ![Manual cash float and deposit sheet used during front closing](assets/01-manual-cash-float.jpg) | ![Manual daily sales reconciliation sheet used for closing totals](assets/02-manual-sales-sheet.jpg) |

---

## Sales Closing

The Sales screen handles the main front-closing calculation.

![Sales closing screen with employee name, closing type, sales values, and cash denominations](assets/03-sales-closing-screen.png)

The app calculates the expected cash amount and shows the closing result.

| Till Money Result                                                                                                   | Bank Deposit Result                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| ![Till money result showing counted denominations and total cash kept in the till](assets/04-till-money-result.png) | ![Bank deposit result showing sales details, denomination breakdown, and deposit total](assets/05-bank-deposit-result.png) |

---

## General Cash Counter

The General screen works as a quick denomination counter for bills, coins, and bundled coins.

![General cash counter screen for entering bills, coins, and coin bundles](assets/06-general-cash-counter.png)

The app creates a clear denomination summary before printing.

![Denomination summary preview showing cash breakdown and final total](assets/07-denomination-summary.png)

---

## Printed Closing Receipts

The app can print closing summaries using a thermal receipt printer.

| Denomination Summary                                                                                      | Till Money                                                                                    | Bank Deposit                                                                                                         |
| --------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| ![Printed denomination summary receipt with cash breakdown and total](assets/08-printed-denomination.jpg) | ![Printed till money receipt showing drawer cash breakdown](assets/09-printed-till-money.jpg) | ![Printed bank deposit receipt showing sales details and deposit cash breakdown](assets/10-printed-bank-deposit.jpg) |

These receipts made the cash count easier to verify because the full denomination breakdown was printed instead of only writing a final total.

---

## DSR Scanner

The DSR Scanner is used to scan the POS/DSR receipt during closing.

![DSR scanner screen with options to select a receipt image or take a photo](assets/11-dsr-scanner.png)

The user can take a photo, crop the receipt, and let the app read the values.

| Receipt Photo                                                           | Receipt Crop                                                                 |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| ![Receipt photo captured for DSR scanning](assets/12-receipt-photo.png) | ![Cropped POS receipt prepared for OCR scanning](assets/13-receipt-crop.png) |

---

## DSR Report

After scanning, the app creates a digital DSR report with the important closing values.

![Digital DSR report generated from scanned receipt values](assets/14-dsr-report.png)

The report helped compare POS values, payment totals, bank deposit amount, and cash difference in one place.

---

## Features

* Front-closing sales calculation
* End-day and mid-day closing support
* Till money and bank deposit calculation
* Cash denomination counting
* Coin bundle counting
* Over/short cash difference check
* DSR receipt scanning
* Digital DSR report generation
* Thermal receipt printing

---

## Built With

* SwiftUI
* iOS camera/photo picker
* OCR receipt scanning
* Thermal printer integration
