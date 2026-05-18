///|
pub fn title() -> String {
  "MoonCraft minimal app"
}

///|
pub fn page() -> String {
  (
    #|<!doctype html>
    #|<html lang="en">
    #|<head>
    #|  <meta charset="utf-8">
    #|  <meta name="viewport" content="width=device-width, initial-scale=1">
    #|  <title>MoonCraft minimal app</title>
    #|  <style>
    #|    body {
    #|      margin: 0;
    #|      font-family: system-ui, sans-serif;
    #|      color: #172026;
    #|      background: #f7f7f4;
    #|    }
    #|    main {
    #|      max-width: 680px;
    #|      margin: 0 auto;
    #|      padding: 64px 24px;
    #|    }
    #|    h1 {
    #|      margin: 0 0 12px;
    #|      font-size: 32px;
    #|    }
    #|    p {
    #|      margin: 0;
    #|      line-height: 1.6;
    #|    }
    #|  </style>
    #|</head>
    #|<body>
    #|  <main>
    #|    <h1>MoonCraft minimal app</h1>
    #|    <p>This page is rendered by MoonBit and served by the preview script.</p>
    #|  </main>
    #|</body>
    #|</html>
  )
}
