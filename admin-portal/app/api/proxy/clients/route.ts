import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';


export const dynamic = "force-dynamic";
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

async function getAuthToken() {
  const cookieStore = await cookies();
  return cookieStore.get('auth_token')?.value || null;
}

// GET all clients
export async function GET(request: NextRequest) {
  try {
    const token = await getAuthToken();
    if (!token) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const queryString = searchParams.toString();
    const url = `${API_BASE_URL}/api/admin/clients${queryString ? `?${queryString}` : ''}`;

    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ 
        message: 'Failed to fetch clients',
        error: 'Backend request failed'
      }));
      console.error('Backend error response:', errorData);
      return NextResponse.json(
        { 
          success: false, 
          error: errorData.error || errorData.message || 'Failed to fetch clients',
          message: errorData.message || 'Failed to fetch clients'
        },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error: any) {
    console.error('Proxy error (GET /clients):', error);
    
    // Handle connection errors
    if (error.message?.includes('fetch') || error.code === 'ECONNREFUSED') {
      return NextResponse.json(
        { 
          success: false, 
          error: 'Backend server is not available. Please ensure the server is running.',
          message: 'Connection failed'
        },
        { status: 503 }
      );
    }
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to fetch clients', 
        message: error.message || 'Unknown error occurred'
      },
      { status: 500 }
    );
  }
}

// POST create new client
export async function POST(request: NextRequest) {
  try {
    const token = await getAuthToken();
    if (!token) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();

    const response = await fetch(`${API_BASE_URL}/api/admin/clients`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error: any) {
    console.error('Proxy error (POST /clients):', error);
    return NextResponse.json(
      { success: false, error: 'Failed to create client', message: error.message },
      { status: 500 }
    );
  }
}

