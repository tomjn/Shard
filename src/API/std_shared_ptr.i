	namespace std {
		template<class T>
		class shared_ptr{
		public:
			T* operator-> () const;
		};
	}
