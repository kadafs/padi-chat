import { useState, useEffect, useRef, useCallback } from 'react';

interface UseLazyLoadOptions {
  threshold?: number;
  root?: Element | null;
  rootMargin?: string;
}

export function useLazyLoad<T>(
  loadMore: () => Promise<T[]>,
  options: UseLazyLoadOptions = {}
): {
  items: T[];
  loading: boolean;
  hasMore: boolean;
  loadMore: () => Promise<void>;
  observerRef: (node: Element | null) => void;
} {
  const { threshold = 0.1, root = null, rootMargin = '100px' } = options;
  const [items, setItems] = useState<T[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const observerRef = useRef<IntersectionObserver | null>(null);
  const elementRef = useRef<Element | null>(null);

  const loadMoreData = useCallback(async () => {
    if (loading || !hasMore) return;

    setLoading(true);
    try {
      const newItems = await loadMore();
      if (newItems.length === 0) {
        setHasMore(false);
      } else {
        setItems((prev) => [...prev, ...newItems]);
      }
    } catch (error) {
      console.error('Error loading more items:', error);
    } finally {
      setLoading(false);
    }
  }, [loadMore, loading, hasMore]);

  const observerCallback = useCallback(
    (node: Element | null) => {
      if (observerRef.current) {
        observerRef.current.disconnect();
      }

      if (node && hasMore && !loading) {
        observerRef.current = new IntersectionObserver(
          (entries) => {
            if (entries[0].isIntersecting) {
              loadMoreData();
            }
          },
          { threshold, root, rootMargin }
        );
        observerRef.current.observe(node);
      }

      elementRef.current = node;
    },
    [hasMore, loading, threshold, root, rootMargin, loadMoreData]
  );

  useEffect(() => {
    return () => {
      if (observerRef.current) {
        observerRef.current.disconnect();
      }
    };
  }, []);

  return {
    items,
    loading,
    hasMore,
    loadMore: loadMoreData,
    observerRef: observerCallback,
  };
}

export default useLazyLoad;

