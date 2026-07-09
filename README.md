# Front Closing App

A personal iOS app I built while working part-time at **New York Fries** to make my front-closing shifts faster, easier to track, and less error-prone.

At my store, closing was divided into **front closing** and **back closing**. I usually handled front closing, which involved counting cash, separating till money and bank deposit money, checking sales totals, filling closing sheets, and matching POS/DSR receipt values.

The manual calculation used to take around **35 minutes**. I built this app as a pet project for my own closing workflow, and it reduced the calculation time to **under 5 minutes**. It also helped track cash clearly and reduced calculation errors significantly.

I could not publish it on the App Store because I did not have an Apple Developer account at the time, but my friends and peers at the store regularly used it from my phone during shifts.

---

## Sales, Till Money, and Bank Deposit

During front closing, I entered the total cash sales, any mid-day cash removal, and the denominations present in the cash register.

At my store, **$100 stayed permanently in the till / cash register** as the standard till float. Anything above that was treated as bank deposit money.

<p align="left">
  <b>Sales closing input</b><br>
  <img src="images/01-sales-closing-input.png" alt="Sales closing input screen" width="250">
</p>

The app calculated the till money and bank deposit split.

<p align="left">
  <b>Bank deposit result</b><br>
  <img src="images/02-bank-deposit-and-till-result.png" alt="Bank deposit result" width="250">
</p>

<p align="left">
  <b>Till money result</b><br>
  <img src="images/02-till-money-result.png" alt="Till money result" width="250">
</p>

If the till was below $100, it showed the missing amount. If it was above $100, it helped split the extra cash from the permanent till float.

<p align="left">
  <b>Printed till money receipt</b><br>
  <img src="images/04-printed-till-money-receipt.jpg" alt="Printed till money receipt" width="250">
</p>

<p align="left">
  <b>Printed bank deposit receipt</b><br>
  <img src="images/05-printed-bank-deposit-receipt.jpg" alt="Printed bank deposit receipt" width="250">
</p>

The final values were copied into the cash float and deposit sheet.

<p align="left">
  <b>Manual cash float / deposit sheet</b><br>
  <img src="images/06-manual-cash-float-deposit-page-2.jpg" alt="Manual cash float deposit sheet" width="250">
</p>

---

## General / Multipurpose Cash Calculator

This was a simple cash calculator for miscellaneous closing calculations. I could enter bills, loose coins, and coin bundles, then print a clean receipt.

<p align="left">
  <b>General calculator input</b><br>
  <img src="images/01-general-calculator-input.png" alt="General calculator input screen" width="250">
</p>

<p align="left">
  <b>Denomination summary preview</b><br>
  <img src="images/02-denomination-summary-preview.png" alt="Denomination summary preview" width="250">
</p>

<p align="left">
  <b>Printed denomination summary</b><br>
  <img src="images/03-printed-denomination-summary.jpg" alt="Printed denomination summary receipt" width="250">
</p>

---

## DSR Scanner

This was one of the most useful features. Instead of manually reading the POS receipt and filling the Daily Sales Reconciliation sheet, the app scanned the receipt, extracted the numbers, and generated the DSR report.

<p align="left">
  <b>DSR scanner start screen</b><br>
  <img src="images/01-dsr-scanner-start.png" alt="DSR scanner start screen" width="250">
</p>

<p align="left">
  <b>Receipt loaded in scanner</b><br>
  <img src="images/06-dsr-scanner-receipt-loaded.png" alt="DSR scanner with loaded receipt" width="250">
</p>

The receipt could be captured, cropped, reviewed, and converted into a report.

<p align="left">
  <b>Camera scan</b><br>
  <img src="images/03-camera-scan-screen.png" alt="Camera scan screen" width="250">
</p>

<p align="left">
  <b>Edit scan / crop</b><br>
  <img src="images/02-edit-scan-crop.png" alt="Edit scan crop screen" width="250">
</p>

<p align="left">
  <b>Review scanned receipt</b><br>
  <img src="images/04-review-scanned-receipt.png" alt="Review scanned receipt" width="250">
</p>

<p align="left">
  <b>DSR report created</b><br>
  <img src="images/05-dsr-report-created.png" alt="DSR report created prompt" width="250">
</p>

The generated report showed the values in Section A and Section B format.

<p align="left">
  <b>Generated DSR Section A</b><br>
  <img src="images/07-generated-dsr-section-a.png" alt="Generated DSR Section A" width="250">
</p>

<p align="left">
  <b>Generated DSR Section B</b><br>
  <img src="images/08-generated-dsr-section-b.png" alt="Generated DSR Section B" width="250">
</p>

These values matched the paper DSR sheet used during closing.

<p align="left">
  <b>Manual Daily Sales Reconciliation sheet</b><br>
  <img src="images/09-manual-dsr-sheet.jpg" alt="Manual Daily Sales Reconciliation sheet" width="250">
</p>

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
