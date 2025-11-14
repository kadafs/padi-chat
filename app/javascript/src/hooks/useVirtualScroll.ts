import { useState, useEffect, useRef, useMemo } from 'react';

interface UseVirtualScrollOptions {
  itemHeight: number;
  containerHeight: number;
  overscan?: number;
}

interface VirtualScrollResult<T> {
  virtualItems: Array<{
    index: number;
    data: T;
    top: number;
    height: number;
  }>;
  totalHeight: number;
  startIndex: number;
  endIndex: number;
}

export function useVirtualScroll<T>(
  items: T[],
  options: UseVirtualScrollOptions
): VirtualScrollResult<T> {
  const { itemHeight, containerHeight, overscan = 3 } = options;
  const [scrollTop, setScrollTop] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const handleScroll = () => {
      setScrollTop(container.scrollTop);
    };

    container.addEventListener('scroll', handleScroll);
    return () => container.removeEventListener('scroll', handleScroll);
  }, []);

  const totalHeight = items.length * itemHeight;
  const startIndex = Math.max(0, Math.floor(scrollTop / itemHeight) - overscan);
  const endIndex = Math.min(
    items.length - 1,
    Math.ceil((scrollTop + containerHeight) / itemHeight) + overscan
  );

  const virtualItems = useMemo(() => {
    return items.slice(startIndex, endIndex + 1).map((data, index) => ({
      index: startIndex + index,
      data,
      top: (startIndex + index) * itemHeight,
      height: itemHeight,
    }));
  }, [items, startIndex, endIndex, itemHeight]);

  return {
    virtualItems,
    totalHeight,
    startIndex,
    endIndex,
  };
}

export default useVirtualScroll;

