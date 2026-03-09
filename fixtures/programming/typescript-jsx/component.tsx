import React from 'react';

interface Props {
  name: string;
  onClick?: () => void;
}

/**
 * A sample component demonstrating JSX syntax
 */
export const Component: React.FC<Props> = ({ name, onClick }) => {
  const template = `Hello, ${name}!`;

  return (
    <>
      <div className="container">
        <h1>{template}</h1>
        <button onClick={onClick}>Click me</button>
      </div>
      <SelfClosing />
      <Nested.Component prop={name} />
    </>
  );
};

// React.Fragment explicit syntax
export const WithFragment = () => (
  <React.Fragment>
    <span>First</span>
    <span>Second</span>
  </React.Fragment>
);

// Empty fragment
export const EmptyFragment = () => <></>;
