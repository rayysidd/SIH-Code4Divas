import { LabelData } from './types';

export enum ProductCategory {
  FOOD_GENERAL = 'FOOD_GENERAL',
  EDIBLE_OIL = 'EDIBLE_OIL',
  COSMETICS = 'COSMETICS',
  ELECTRONICS = 'ELECTRONICS',
  GENERAL = 'GENERAL',
  UNKNOWN = 'UNKNOWN'
}

/**
 * Derives the strict product category based on raw GTIN classification or text keywords.
 */
export function determineProductCategory(labelData: LabelData): ProductCategory {
  // If explicitly provided by external lookup (e.g. GS1 DB via labelData)
  if (labelData.productCategory === 'EDIBLE_OIL') return ProductCategory.EDIBLE_OIL;
  if (labelData.productCategory === 'COSMETICS') return ProductCategory.COSMETICS;
  if (labelData.productCategory === 'FOOD') return ProductCategory.FOOD_GENERAL;

  // Fallback to heuristic classification based on generic name
  const genericNameDecl = labelData.declarations['GENERIC_NAME'];
  if (genericNameDecl && genericNameDecl.present) {
    const text = genericNameDecl.rawText.toLowerCase();
    
    if (text.includes('oil') && (text.includes('edible') || text.includes('sunflower') || text.includes('mustard'))) {
      return ProductCategory.EDIBLE_OIL;
    }
    
    if (text.includes('shampoo') || text.includes('soap') || text.includes('cream') || text.includes('lotion')) {
      return ProductCategory.COSMETICS;
    }

    if (text.includes('biscuit') || text.includes('snack') || text.includes('food')) {
      return ProductCategory.FOOD_GENERAL;
    }
  }

  return ProductCategory.GENERAL;
}
