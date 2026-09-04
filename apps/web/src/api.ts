/**
 * Frontend API connection to FastAPI backend.
 * Points to http://localhost:8000 by default.
 */

const API_BASE_URL = 'http://localhost:8000/v1';

export const apiClient = {
  /**
   * Submit a label image for compliance scanning.
   */
  async scanLabel(file: File, token: string = "dummy-token") {
    const formData = new FormData();
    formData.append('images', file);
    
    // Default assumptions for the hackathon MVP
    formData.append('rule_version', '2024.01');

    try {
      const response = await fetch(`${API_BASE_URL}/check/label`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error("Error scanning label:", error);
      throw error;
    }
  },

  /**
   * Verify an e-commerce listing for compliance.
   */
  async checkListing(listingUrl: string, token: string = "dummy-token") {
    try {
      const response = await fetch(`${API_BASE_URL}/check/listing`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ listing_url: listingUrl }),
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error("Error checking listing:", error);
      throw error;
    }
  },

  /**
   * Reconcile physical label vs e-commerce listing
   */
  async crossChannelReconciliation(scanId: string, listingUrl: string, token: string = "dummy-token") {
    try {
      const response = await fetch(`${API_BASE_URL}/check/crosschannel`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ scan_id: scanId, listing_url: listingUrl }),
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error("Error cross-channel reconciling:", error);
      throw error;
    }
  },
  
  /**
   * Check system health
   */
  async checkHealth() {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      return await response.json();
    } catch (error) {
      console.error("Health check failed:", error);
      return { status: "offline" };
    }
  }
};
