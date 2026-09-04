export const motion = {
  durations: {
    instant: '0ms',
    fast: '100ms',
    normal: '200ms',
    slow: '350ms',
    page: '400ms',
    scanPulse: '1500ms',
    resultReveal: '500ms',
  },
  easings: {
    fast: 'ease-out',
    normal: 'ease-in-out',
    slow: 'cubic-bezier(0.4, 0, 0.2, 1)',
    page: 'cubic-bezier(0.4, 0, 0.2, 1)',
    scanPulse: 'ease-in-out',
    resultReveal: 'cubic-bezier(0.34, 1.56, 0.64, 1)', // Custom spring approximation
  }
};
