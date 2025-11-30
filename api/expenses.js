// Vercel Serverless Function for Expense API
// Uses Vercel KV for data storage

export const config = {
  runtime: 'edge',
};

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default async function handler(request) {
  // Handle CORS preflight
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: CORS_HEADERS });
  }

  const url = new URL(request.url);
  const userId = url.searchParams.get('userId') || 'default';

  try {
    switch (request.method) {
      case 'GET':
        return await getExpenses(userId);
      case 'POST':
        return await createExpense(request, userId);
      case 'PUT':
        return await updateExpense(request, userId);
      case 'DELETE':
        return await deleteExpense(url, userId);
      default:
        return new Response(JSON.stringify({ error: 'Method not allowed' }), {
          status: 405,
          headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
        });
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }
}

async function getExpenses(userId) {
  // In production, use Vercel KV or Postgres
  // For now, return empty array (data stored client-side)
  return new Response(JSON.stringify({ expenses: [], userId }), {
    status: 200,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

async function createExpense(request, userId) {
  const body = await request.json();
  // Validate expense data
  if (!body.title || !body.amount || !body.date) {
    return new Response(JSON.stringify({ error: 'Missing required fields' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }

  // In production, save to database
  return new Response(JSON.stringify({ success: true, expense: body }), {
    status: 201,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

async function updateExpense(request, userId) {
  const body = await request.json();
  if (!body.id) {
    return new Response(JSON.stringify({ error: 'Missing expense ID' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ success: true, expense: body }), {
    status: 200,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

async function deleteExpense(url, userId) {
  const expenseId = url.searchParams.get('id');
  if (!expenseId) {
    return new Response(JSON.stringify({ error: 'Missing expense ID' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ success: true, id: expenseId }), {
    status: 200,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
