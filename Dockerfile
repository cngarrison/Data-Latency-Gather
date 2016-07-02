FROM perl:5.24
RUN cpanm -f Moose MooseX::Getopt::Usage MooseX::Getopt::Usage::Role::Man 
RUN cpanm -f Data::Printer Log::Dispatchouli Log::Contextual::WarnLogger::Fancy Try::Tiny 
RUN cpanm -f AnyEvent AnyEvent::Ping 
COPY . /usr/src/data-latency-gather
WORKDIR /usr/src/data-latency-gather
CMD [ "perl", "./check-latency.pl", "print_data", "-v" ]
