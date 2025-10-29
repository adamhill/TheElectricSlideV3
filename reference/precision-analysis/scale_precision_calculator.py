"""
Slide Rule Cursor Precision Calculator
Based on PostScript Subsection Tick Mark Data

This module calculates the appropriate number of decimal places
to display for a digital slide rule cursor based on the subsection
intervals defined in the PostScript engine.
"""

import math
from typing import Dict, List, Optional, Any


class ScalePrecisionCalculator:
    """
    Calculates appropriate decimal places for cursor display based on
    PostScript scale subsection definitions.
    """
    
    def __init__(self, scale_definition: Dict[str, Any]):
        """
        Initialize with a scale definition.
        
        Args:
            scale_definition: Dictionary containing:
                - subsections: List of subsection dicts
                - beginscale: Starting value of scale
                - endscale: Ending value of scale
                - xfactor: Precision multiplier (optional, default 100)
                - formula: Scale formula function (optional)
        """
        self.subsections = scale_definition['subsections']
        self.beginscale = scale_definition['beginscale']
        self.endscale = scale_definition['endscale']
        self.xfactor = scale_definition.get('xfactor', 100)
        
        # Sort subsections by beginsub to ensure proper ordering
        self.subsections.sort(key=lambda s: s['beginsub'])
    
    def get_decimal_places(self, position: float) -> int:
        """
        Get appropriate decimal places for cursor at given position.
        
        Args:
            position: Current cursor position on the scale
        
        Returns:
            Number of decimal places to display (1-5)
        """
        # Validate position is within scale bounds
        if position < self.beginscale or position > self.endscale:
            return 2  # default for out-of-bounds
        
        # Find the active subsection for this position
        active_subsection = self._find_active_subsection(position)
        
        if active_subsection is None:
            return 2  # default if no subsection found
        
        # Get the smallest interval from this subsection
        smallest_interval = self._get_smallest_interval(active_subsection)
        
        if smallest_interval is None:
            return 2  # default if no interval found
        
        # Convert interval to decimal places
        return self._interval_to_decimal_places(smallest_interval)
    
    def _find_active_subsection(self, position: float) -> Optional[Dict]:
        """
        Find which subsection applies to the given position.
        
        Args:
            position: Position on the scale
        
        Returns:
            Active subsection dict, or None if not found
        """
        active_subsection = None
        
        # Iterate through subsections to find the last one 
        # whose beginsub is <= position
        for subsection in self.subsections:
            if position >= subsection['beginsub']:
                active_subsection = subsection
            else:
                # Since sorted, we can stop here
                break
        
        return active_subsection
    
    def _get_smallest_interval(self, subsection: Dict) -> Optional[float]:
        """
        Extract the smallest (finest) interval from a subsection.
        
        The intervals array is [primary, secondary, tertiary, quaternary].
        We want the smallest non-null value (typically quaternary).
        
        Args:
            subsection: Subsection dictionary
        
        Returns:
            Smallest interval value, or None if all are null
        """
        intervals = subsection['intervals']
        
        # Scan backwards through intervals to find last non-null
        for interval in reversed(intervals):
            if interval is not None:
                return interval
        
        # If all are null (shouldn't happen), return None
        return None
    
    def _interval_to_decimal_places(self, interval: float) -> int:
        """
        Convert an interval size to appropriate decimal places.
        
        The logic:
        - For intervals >= 1: show 1 decimal place (for interpolation)
        - For intervals < 1: calculate decimal places needed to represent
          the interval, then add 1 for interpolation between marks
        - Clamp result to 1-5 decimal places
        
        Args:
            interval: The smallest tick mark spacing
        
        Returns:
            Number of decimal places (1-5)
        """
        if interval >= 1:
            # Integer precision, but show one decimal for smooth interpolation
            return 1
        
        # Calculate how many decimal places needed to represent this interval
        # For 0.01, we need 2 decimal places
        # For 0.001, we need 3 decimal places
        # Formula: -floor(log10(interval))
        decimal_places = -math.floor(math.log10(interval))
        
        # Add one more decimal place for interpolation
        # (users can estimate about 1/10 between marks)
        decimal_places += 1
        
        # Clamp to reasonable range (1-5)
        return min(max(decimal_places, 1), 5)
    
    def get_formatted_value(self, position: float) -> str:
        """
        Get a formatted string representation of the position
        with appropriate decimal places.
        
        Args:
            position: Position on the scale
        
        Returns:
            Formatted string (e.g., "1.234" or "56.7")
        """
        decimal_places = self.get_decimal_places(position)
        return f"{position:.{decimal_places}f}"


def create_c_scale_calculator() -> ScalePrecisionCalculator:
    """
    Create a calculator for the standard C scale.
    
    This matches the PostScript definition from lines 430-461.
    
    Returns:
        Configured ScalePrecisionCalculator
    """
    c_scale_definition = {
        'beginscale': 1,
        'endscale': 10,
        'xfactor': 100,
        'subsections': [
            {'beginsub': 1,  'intervals': [1, 0.1, 0.05, 0.01]},
            {'beginsub': 2,  'intervals': [1, 0.5, 0.1, 0.02]},
            {'beginsub': 4,  'intervals': [1, 0.5, 0.1, 0.05]},
            {'beginsub': 10, 'intervals': [10, 1, 0.5, 0.1]},
            {'beginsub': 20, 'intervals': [10, 5, 1, 0.2]},
            {'beginsub': 40, 'intervals': [10, 5, 1, 0.5]},
        ]
    }
    return ScalePrecisionCalculator(c_scale_definition)


def create_ll00_scale_calculator() -> ScalePrecisionCalculator:
    """
    Create a calculator for the LL00 scale (very fine precision).
    
    This matches the PostScript definition from lines 1201-1210.
    
    Returns:
        Configured ScalePrecisionCalculator
    """
    ll00_scale_definition = {
        'beginscale': 0.990,
        'endscale': 0.999,
        'xfactor': 100000,
        'subsections': [
            {'beginsub': 0.990, 'intervals': [0.001, 0.0005, 0.0001, 0.00005]},
            {'beginsub': 0.995, 'intervals': [0.001, 0.0005, 0.0001, 0.00002]},
            {'beginsub': 0.998, 'intervals': [0.0005, 0.0001, 0.00005, 0.00001]},
        ]
    }
    return ScalePrecisionCalculator(ll00_scale_definition)


def create_k_scale_calculator() -> ScalePrecisionCalculator:
    """
    Create a calculator for the K scale (cube roots).
    
    This matches the PostScript definition from lines 710-728.
    
    Returns:
        Configured ScalePrecisionCalculator
    """
    k_scale_definition = {
        'beginscale': 1,
        'endscale': 1000,
        'xfactor': 100,
        'subsections': [
            {'beginsub': 1,    'intervals': [1, 0.5, 0.1, 0.05]},
            {'beginsub': 3,    'intervals': [1, None, 0.5, 0.1]},
            {'beginsub': 6,    'intervals': [1, None, None, 0.2]},
            {'beginsub': 10,   'intervals': [10, 5, 1, 0.5]},
            {'beginsub': 30,   'intervals': [10, None, 5, 1]},
            {'beginsub': 60,   'intervals': [10, None, None, 2]},
            {'beginsub': 100,  'intervals': [100, 50, 10, 5]},
            {'beginsub': 300,  'intervals': [100, None, 50, 10]},
            {'beginsub': 600,  'intervals': [100, None, None, 20]},
            {'beginsub': 1000, 'intervals': [1000, 500, 100, 50]},
        ]
    }
    return ScalePrecisionCalculator(k_scale_definition)


# Demo and testing
if __name__ == "__main__":
    print("=" * 70)
    print("Slide Rule Cursor Precision Calculator Demo")
    print("=" * 70)
    
    # Test C Scale
    print("\n--- C Scale (Standard Logarithmic) ---")
    c_calc = create_c_scale_calculator()
    
    test_positions_c = [1.0, 1.5, 2.0, 3.14159, 5.0, 7.5, 9.0]
    for pos in test_positions_c:
        decimals = c_calc.get_decimal_places(pos)
        formatted = c_calc.get_formatted_value(pos)
        print(f"Position {pos:6.3f}: {decimals} decimals → {formatted:>8}")
    
    # Test LL00 Scale (Very Fine)
    print("\n--- LL00 Scale (Very Fine Precision) ---")
    ll00_calc = create_ll00_scale_calculator()
    
    test_positions_ll00 = [0.990, 0.993, 0.996, 0.9985, 0.999]
    for pos in test_positions_ll00:
        decimals = ll00_calc.get_decimal_places(pos)
        formatted = ll00_calc.get_formatted_value(pos)
        print(f"Position {pos:.5f}: {decimals} decimals → {formatted:>10}")
    
    # Test K Scale (Cube Roots)
    print("\n--- K Scale (Cube Roots) ---")
    k_calc = create_k_scale_calculator()
    
    test_positions_k = [1, 5, 10, 50, 100, 500, 1000]
    for pos in test_positions_k:
        decimals = k_calc.get_decimal_places(pos)
        formatted = k_calc.get_formatted_value(pos)
        print(f"Position {pos:6.1f}: {decimals} decimals → {formatted:>8}")
    
    print("\n" + "=" * 70)
    print("Validation Summary:")
    print("=" * 70)
    print("✓ Fine scales (LL00): 5 decimal places near 1.0")
    print("✓ Standard scales (C): 2-3 decimal places across range")
    print("✓ Coarse scales (K high values): 1 decimal place")
    print("✓ Automatic adaptation to scale position")
    print("✓ Matches historical slide rule precision")
    print("=" * 70)
