# Front Closing App

A personal iOS app I built while working part-time at **New York Fries** to make front-closing shifts faster, easier to track, and less error-prone.

At my store, closing was split into **front closing** and **back closing**. I usually handled front closing, which involved counting cash, separating till money and bank deposit money, checking sales totals, filling closing sheets, and matching POS / DSR receipt values.

The manual calculation process usually took around **35 minutes**. I built this app for my own closing workflow, and it reduced the calculation time to **under 5 minutes** while making cash tracking clearer and reducing calculation mistakes.

I could not publish it on the App Store because I did not have an Apple Developer account at the time, but my friends and peers at the store regularly used it from my phone during shifts.

---

## Sales, Till Money, and Bank Deposit

During front closing, I entered the total cash sales, any mid-day cash removal, and the denominations present in the cash register.

At my store, **$100 stayed permanently in the till / cash register** as the standard till float. Anything above that was treated as bank deposit money.

|                                     Sales Closing Input                                    |                                      Bank Deposit Result                                     |                                Till Money Result                                |
| :----------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------: |
| <img src="images/01-sales-closing-input.png" alt="Sales closing input screen" width="220"> | <img src="images/02-bank-deposit-and-till-result.png" alt="Bank deposit result" width="220"> | <img src="images/02-till-money-result.png" alt="Till money result" width="220"> |

The app calculated the split between the permanent till float and the money that needed to be deposited.

If the till was below $100, the app showed the missing amount. If it was above $100, it helped separate the extra cash from the permanent till float.

|                                     Printed Bank Deposit Receipt                                    |                                      Printed Till Money Receipt                                     |
| :-----------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------: |
| <img src="images/05-printed-bank-deposit-receipt.jpg" alt="Printed bank deposit receipt" width="260"> | <img src="images/04-printed-till-money-receipt.jpg" alt="Printed till money receipt" width="260"> |

The final values were copied into the cash float and deposit sheet.

|                                       Manual Cash Float / Deposit Sheet                                      |
| :----------------------------------------------------------------------------------------------------------: |
| <img src="images/06-manual-cash-float-deposit-page-2.jpg" alt="Manual cash float deposit sheet" width="320"> |

---

## General / Multipurpose Cash Calculator

This was a simple cash calculator for miscellaneous closing calculations. I could enter bills, loose coins, and coin bundles, then print a clean receipt summary.

|                                       General Calculator Input                                       |                                      Denomination Summary Preview                                     |                                          Printed Denomination Summary                                         |
| :--------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------: |
| <img src="images/01-general-calculator-input.png" alt="General calculator input screen" width="220"> | <img src="images/02-denomination-summary-preview.png" alt="Denomination summary preview" width="220"> | <img src="images/03-printed-denomination-summary.jpg" alt="Printed denomination summary receipt" width="220"> |

---

## DSR Scanner

This was one of the most useful features. Instead of manually reading the POS receipt and filling the Daily Sales Reconciliation sheet, the app scanned the receipt, extracted the numbers, and generated the DSR report.

|                                    DSR Scanner Start                                   |                                    Camera Scan                                    |                                 Edit Scan / Crop                                 |                                   Review Scanned Receipt                                  |
| :------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------: | :------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------: |
| <img src="images/01-dsr-scanner-start.png" alt="DSR scanner start screen" width="170"> | <img src="images/03-camera-scan-screen.png" alt="Camera scan screen" width="170"> | <img src="images/02-edit-scan-crop.png" alt="Edit scan crop screen" width="170"> | <img src="images/04-review-scanned-receipt.png" alt="Review scanned receipt" width="170"> |

The receipt could be captured, cropped, reviewed, and converted into a report.

|                                    DSR Report Created                                    |                                        Receipt Loaded in Scanner                                       |
| :--------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------: |
| <img src="images/05-dsr-report-created.png" alt="DSR report created prompt" width="260"> | <img src="images/06-dsr-scanner-receipt-loaded.png" alt="DSR scanner with loaded receipt" width="260"> |

The generated report showed the extracted values in Section A and Section B format.

|                                   Generated DSR Section A                                   |                                   Generated DSR Section B                                   |
| :-----------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------: |
| <img src="images/07-generated-dsr-section-a.png" alt="Generated DSR Section A" width="260"> | <img src="images/08-generated-dsr-section-b.png" alt="Generated DSR Section B" width="260"> |

These values matched the paper DSR sheet used during closing.

|                                           Manual DSR Sheet                                           |
| :--------------------------------------------------------------------------------------------------: |
| <img src="images/09-manual-dsr-sheet.jpg" alt="Manual Daily Sales Reconciliation sheet" width="320"> |

---

## Features

* Sales, till money, and bank deposit calculation
* Permanent $100 till float tracking
* Over / short cash difference check
* Multipurpose cash and coin bundle calculator
* Printable receipt summaries
* DSR receipt scanning and cropping
* OCR-based DSR value extraction
* Generated DSR report with Section A and Section B

---

## Built With

* SwiftUI
* iOS camera and photo picker
* OCR / text recognition
* Thermal receipt printer integration
