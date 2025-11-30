// Tax Number Validation API
export const config = {
  runtime: 'edge',
};

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default async function handler(request) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: CORS_HEADERS });
  }

  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }

  try {
    const { taxNumber } = await request.json();
    
    if (!taxNumber) {
      return new Response(JSON.stringify({ valid: false, error: 'Tax number required' }), {
        status: 400,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const isValid = validateUnifiedSocialCreditCode(taxNumber);
    
    return new Response(JSON.stringify({ 
      valid: isValid, 
      taxNumber,
      message: isValid ? '税号格式正确' : '税号格式无效'
    }), {
      status: 200,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ valid: false, error: error.message }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }
}

// 统一社会信用代码验证
function validateUnifiedSocialCreditCode(code) {
  if (!code || typeof code !== 'string') return false;
  
  const upperCode = code.toUpperCase();
  
  // 18位统一社会信用代码正则
  const regex = /^[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}$/;
  
  if (!regex.test(upperCode)) return false;
  
  // 校验码验证
  const weights = [1, 3, 9, 27, 19, 26, 16, 17, 20, 29, 25, 13, 8, 24, 10, 30, 28];
  const chars = '0123456789ABCDEFGHJKLMNPQRTUWXY';
  
  let sum = 0;
  for (let i = 0; i < 17; i++) {
    const charIndex = chars.indexOf(upperCode[i]);
    if (charIndex === -1) return false;
    sum += charIndex * weights[i];
  }
  
  const checkCode = (31 - (sum % 31)) % 31;
  const expectedChar = chars[checkCode];
  
  return upperCode[17] === expectedChar;
}
