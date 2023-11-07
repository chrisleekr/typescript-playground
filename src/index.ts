import server from './server';

const port = process.env.PORT || 8091;
server.listen(port, () => {
  console.log(`Listening port: ${port}`);
});
