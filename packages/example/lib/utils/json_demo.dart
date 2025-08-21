const jsonDemo = {
  "id": "a1b2c3d4-e5f6-7890-1234-56789abcdef0",
  "name": "Acme Corp Annual Report 2024",
  "version": 3,
  "isActive": true,
  "releaseDate": "2024-05-15T10:30:00Z",
  "author": {
    "firstName": "Jane",
    "lastName": "Doe",
    "email": "jane.doe@example.com",
    "roles": ["editor", "reviewer", "admin"],
    "contact": {
      "phone": "+1-555-123-4567",
      "address": {"street": "123 Main St", "city": "Anytown", "zipCode": "12345", "country": "USA"},
    },
  },
  "sections": [
    {
      "sectionId": "sec-001",
      "title": "Executive Summary",
      "pageRange": "1-5",
      "content": "A high-level overview of the year's performance and key achievements.",
      "keywords": ["summary", "performance", "achievements"],
      "figures": [
        {"figureId": "fig-001", "caption": "Revenue Growth Chart", "url": "https://example.com/charts/revenue.png"},
        {
          "figureId": "fig-002",
          "caption": "Market Share Distribution",
          "url": "https://example.com/charts/market_share.png",
        },
      ],
    },
    {
      "sectionId": "sec-002",
      "title": "Financial Performance",
      "pageRange": "6-20",
      "content": "Detailed financial statements including revenue, expenses, and profits.",
      "keywords": ["finance", "revenue", "expenses", "profit"],
      "dataTables": [
        {
          "tableId": "tbl-001",
          "name": "Quarterly Revenue",
          "headers": ["Quarter", "2022", "2023", "2024"],
          "rows": [
            ["Q1", 1000000, 1200000, 1500000],
            ["Q2", 1100000, 1300000, 1600000],
            ["Q3", 1050000, 1250000, 1550000],
            ["Q4", 1150000, 1350000, 1650000],
          ],
          "notes": "All figures in USD.",
        },
      ],
    },
    {
      "sectionId": "sec-003",
      "title": "Product Development",
      "pageRange": "21-30",
      "content": "Updates on new product launches and R&D initiatives.",
      "keywords": ["products", "R&D", "innovation"],
      "productsLaunched": [
        {"name": "Product A", "status": "released", "launchDate": "2024-01-20"},
        {"name": "Product B", "status": "beta", "launchDate": null},
      ],
    },
  ],
  "metadata": {
    "creationTool": "ReportGen v1.0",
    "lastModifiedBy": "John Smith",
    "lastModifiedDate": "2024-05-16T09:00:00Z",
    "tags": ["annual-report", "2024", "company", "business"],
    "customFields": {"projectCode": "AR2024-XYZ", "department": "Finance"},
  },
  "history": [
    {
      "version": 1,
      "changeLog": "Initial draft created.",
      "changedBy": "Jane Doe",
      "changeDate": "2024-04-01T08:00:00Z",
    },
    {
      "version": 2,
      "changeLog": "Added financial data and product updates.",
      "changedBy": "John Smith",
      "changeDate": "2024-05-10T14:00:00Z",
    },
  ],
  "settings": {
    "language": "en-US",
    "theme": "dark",
    "notificationsEnabled": true,
    "preferences": {"fontSize": 14, "layout": "compact"},
  },
};
