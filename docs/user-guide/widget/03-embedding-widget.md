# Embedding the Widget on Your Website

Once you have configured your widget's settings, the final step is to embed it into your own website. This is done by copying a small snippet of HTML code from BookBed and pasting it into your website's editor.

## 1. Get the Embed Code

1.  **Go to the Widget Settings Tab:** In the Unit Hub for the desired unit, go to the "Widget Settings" tab.
2.  **Find the Embed Code:** Look for a section titled "Embed Widget" or "Get Code".
3.  **Copy the Code:** You will see a text box containing a snippet of HTML code, which will likely be an `<iframe>`. Click the "Copy" button to copy the entire snippet to your clipboard.

## 2. Paste the Code into Your Website

Now, you need to edit the page on your website where you want the booking widget to appear.

*   **For a standard HTML website:**
    *   Open the HTML file for the page in a text editor.
    *   Paste the code snippet into the `<body>` of the page where you want the widget to be displayed.

*   **For WordPress:**
    1.  Edit the page or post where you want to add the widget.
    2.  Switch from the "Visual" editor to the "Text" or "Code" editor.
    3.  Paste the code snippet in the desired location.
    4.  Alternatively, use a "Custom HTML" block in the Gutenberg editor and paste the code there.

*   **For Wix, Squarespace, or other website builders:**
    1.  Look for an option to add "Custom HTML", "Embed a widget", or "Code block".
    2.  Drag this element onto your page.
    3.  Paste the copied `<iframe>` code into the element's settings.

## 3. Adjusting Width and Height

The embed code may include `width` and `height` attributes. You can adjust these to fit the layout of your page. For a responsive design that works well on mobile devices, it's often best to set the width to `100%`.

**Example Code Snippet:**
```html
<iframe
  src="https://view.bookbed.io/?property=YOUR_PROPERTY_ID&unit=YOUR_UNIT_ID"
  width="100%"
  height="700"
  style="border: none; min-height: 500px; max-height: 850px;"
  loading="lazy">
</iframe>
```

## 4. Test the Embedded Widget

After saving the changes on your website, open the page in your browser to see the live widget. Test the booking process to ensure it works as you expect. Check it on both a desktop and a mobile device to ensure it looks good everywhere.

_Screenshot placeholder: The "Embed Widget" section in BookBed showing the code snippet to be copied._
